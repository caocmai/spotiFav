//
//  ViewController.swift
//  SpotiFav
//
//  Created by Cao Mai on 9/14/20.
//  Copyright © 2020 Cao. All rights reserved.
//

import UIKit
import AuthenticationServices


class MyTopArtists: UIViewController {

    private let client = APIClient(configuration: URLSessionConfiguration.default)
    private let artistsTableView = UITableView()
    private var artists = [ArtistItem]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAndConfigureTable()
        configureNavBar()
        
    }
    
    private func fetchAndConfigureTable() {
        let token = (UserDefaults.standard.string(forKey: "token"))
//        let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        
        if token == nil {
            emptyMessage(message: "Tap Auth Spotify To Authenticate!", duration: 1.20)
        } else {
            client.call(request: .getUserTopArtists(token: token!, completions: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                    print("got back completion; error")
                case .success(let results):
                    self.artists = results.items
                    DispatchQueue.main.async {
                        self.configureTableView()
                    }
                }
            }))
        }
    }
    
    private func configureNavBar() {
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Top Artists"
        let authSpotifyBarButton = UIBarButtonItem(title: "Auth Spotify", style: .plain, target: self, action: #selector(authButtontapped))
        self.navigationItem.rightBarButtonItem = authSpotifyBarButton
        
         let myTopTracks = UIBarButtonItem(title: "Top Tracks", style: .plain, target: self, action: #selector(topTracksTapped))
        self.navigationItem.leftBarButtonItem = myTopTracks
    }
    
    @objc func authButtontapped() {
        getSpotifyAccessCode()
    }
    
    @objc func topTracksTapped() {
        let topTracksVC = MyTopTracks()
        let navController = UINavigationController(rootViewController: topTracksVC)
        self.present(navController, animated: true)
    }
    
    private func configureTableView() {
        artistsTableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(artistsTableView)
        artistsTableView.register(TableCell.self, forCellReuseIdentifier: String(describing: type(of: TableCell.self)))
        artistsTableView.dataSource = self
        artistsTableView.delegate = self
        artistsTableView.frame = self.view.bounds
        artistsTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    private func getSpotifyAccessCode() {
        let urlRequest = client.getSpotifyAccessCodeURL()
        print(urlRequest)
        let scheme = "auth"
        let session = ASWebAuthenticationSession(url: urlRequest, callbackURLScheme: scheme) { (callbackURL, error) in
            guard error == nil, let callbackURL = callbackURL else { return }
            
            let queryItems = URLComponents(string: callbackURL.absoluteString)?.queryItems
            guard let requestAccessCode = queryItems?.first(where: { $0.name == "code" })?.value else { return }
            print(" Code \(requestAccessCode)")
//            UserDefaults.standard.set(requestAccessCode, forKey: "requestAccessCode")
            
            // exchanges access code to access token with refresh token
            self.client.call(request: .accessCodeToAccessToken(code: requestAccessCode, completion: { (token) in
                print(token)
                switch token {
                case .failure(let error):
                    print(error)
                case .success(let token):
                    UserDefaults.standard.set(token.accessToken, forKey: "token")
                    UserDefaults.standard.set(token.refreshToken, forKey: "refresh_token")
                    self.fetchAndConfigureTable()
                }
            }))
            
        }
        session.presentationContextProvider = self
        session.start()
    }
    
}

extension MyTopArtists: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
        
    }
}

extension MyTopArtists: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: type(of: TableCell.self))) as! TableCell
        cell.accessoryType = .disclosureIndicator

        let artist = artists[indexPath.row]
        cell.setArtist(artist: artist)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let artist = artists[indexPath.row]
        
        let destinationVC = ArtistTopTracksVC()
        destinationVC.artist = artist
        artistsTableView.deselectRow(at: indexPath, animated: true)
        self.navigationController?.pushViewController(destinationVC, animated: true)
    }
    
}
