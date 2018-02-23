//
//  JournalViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 2/22/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import UIKit

class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var dateArray = [".", "February 8, 2018", "February 14, 2018", "February 20, 2018", "February 22, 2018", "February 8, 2018", "February 14, 2018", "February 20, 2018", "February 22, 2018"]
    var emojiArray = [".", "😴", "😔", "😏", "😡", "😴", "😔", "😏", "😡"]
    var emotionsArray = [".","sleepy, sad", "sad, mellow", "cheeky, happy", "angry, meh", "sleepy, sad", "sad, mellow", "cheeky, happy", "angry, meh"]
    
    private var animatedGradientView : AnimatedGradientView?
    let cellSpacingHeight: CGFloat = 0.000001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
        animatedGradientView = AnimatedGradientView(frame: self.view.bounds)
        self.view.addSubview(animatedGradientView!)
        
        var tableRect = self.view.frame
        
        tableRect.origin.x += 15
        tableRect.size.width -= 30
        
        let tableView = UITableView(frame: tableRect, style: UITableViewStyle.grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.left:
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromRight
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                present(RecordViewController(), animated: false, completion: nil)
                print("left swipe")
            default:
                break
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0){
            return 200
        }
        return 85
    }
    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dateArray.count
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            let cell = GraphTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "graphTableViewCell")
            cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            return cell
        } else {
            let cell = JournalTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "journalEntryTableViewCell")
            cell.backgroundColor = UIColor(white: 1, alpha: 0.5)
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            cell.dateLabel.text = dateArray[indexPath.section]
            cell.emojiLabel.text = emojiArray[indexPath.section]
            cell.emotionLabel.text = emotionsArray[indexPath.section]
            return cell
        }
    }
    
}
