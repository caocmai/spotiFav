//
//  PlaylistTableVC.swift
//  SpotiFav
//
//  Created by Cao Mai on 9/27/20.
//  Copyright © 2020 Cao. All rights reserved.
//

import UIKit

//// Currently getting the global top 50 tracks
class PlaylistTableVC: UIViewController {
    
    private let apiClient = APIClient(configuration: URLSessionConfiguration.default)
    private var tableViewTracks = UITableView()
    private var simplifiedTracks = [SimpleTrack]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchAndConfigure()
    }
    
    private func fetchAndConfigure() {
        let global50 = "37i9dQZEVXbMDoHDwVN2tF"
        let token = UserDefaults.standard.string(forKey: "token")
        //        print(token)
        if token == nil {
            emptyMessage(message: "Tap Login Spotify", duration: 1.20)
        } else {
            apiClient.call(request: .getPlaylist(token: token!, playlistId: global50, completions: { (playlist) in
                switch playlist {
                case .failure(let error):
                    print(error)
                case .success(let playlist):
                    for track in playlist.tracks.items {
                        let newTrack = SimpleTrack(artistName: track.track.artists.first?.name,
                                                   id: track.track.id,
                                                   title: track.track.name,
                                                   previewURL: track.track.previewUrl,
                                                   images: track.track.album!.images)
                        self.simplifiedTracks.append(newTrack)
                    }
                    
                    DispatchQueue.main.async {
                        self.navigationItem.title = playlist.name
                        self.configureTableView()
                    }
                }
            }))
        }
    }
    
    private func configureTableView() {
        self.view.addSubview(tableViewTracks)
        tableViewTracks.translatesAutoresizingMaskIntoConstraints = false
        tableViewTracks.dataSource = self
        tableViewTracks.delegate = self
        tableViewTracks.register(TableCell.self, forCellReuseIdentifier: String(describing: type(of: TableCell.self)))
        tableViewTracks.frame = self.view.bounds
        tableViewTracks.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
}

// MARK: - UITableView
extension PlaylistTableVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        simplifiedTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: type(of: TableCell.self)), for: indexPath) as! TableCell
        
        cell.simplifiedTrack = simplifiedTracks[indexPath.row]
        cell.setTrack(song: simplifiedTracks[indexPath.row], hideHeartButton: false)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    
}

