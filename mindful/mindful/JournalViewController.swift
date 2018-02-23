//
//  JournalViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 2/22/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import UIKit

class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dateArray = ["February 8, 2018", "February 14, 2018", "February 20, 2018", "February 22, 2018"]
    var emojiArray = ["😴", "😔", "😏", "😡"]
    var emotionsArray = ["sleepy, sad", "sad, mellow", "cheeky, happy", "angry, meh"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tableView = UITableView(frame: view.bounds, style: UITableViewStyle.grouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = JournalTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "myIdentifier")
        cell.dateLabel.text = dateArray[indexPath.row]
        cell.emojiLabel.text = emojiArray[indexPath.row]
        cell.emotionLabel.text = emotionsArray[indexPath.row]
        return cell
    }
    
}
