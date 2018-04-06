//
//  JournalViewController.swift
//  mindful
//
//  Created by Daniel Moreno on 2/22/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Charts
class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    fileprivate(set) var auth:Auth?
    
    fileprivate(set) var ref: DatabaseReference!
    
//    var dateArray = [".", "February 8, 2018", "February 14, 2018", "February 20, 2018", "February 22, 2018", "February 8, 2018", "February 14, 2018", "February 20, 2018", "February 22, 2018"]
//    var emojiArray = [".", "😴", "😔", "😏", "😡", "😴", "😔", "😏", "😡"]
//    var emotionsArray = [".","sleepy, sad", "sad, mellow", "cheeky, happy", "angry, meh", "sleepy, sad", "sad, mellow", "cheeky, happy", "angry, meh"]
    
    //
    
    var emojiMap = ["anger": "😡",
                    "contempt": "🙄",
                    "disgust": "🤢",
                    "fear": "😨",
                    "joy": "😃",
                    "sadness": "😔",
                    "surprise": "😮"]
    var dateArray =  [String]()
    var emojiArray = [String]()
    var emotionsArray = [String]()
    
    var lineChart: LineChartView!
    

    private var animatedGradientView : AnimatedGradientView?
    let cellSpacingHeight: CGFloat = 0.000001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        self.ref = Database.database().reference()
        self.auth = Auth.auth()
        let user = auth?.currentUser
        let uid = user?.uid
        
        ref?.child("/user-entries/\(uid ?? "NOUSERID")/").observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Get user value
            let entries = snapshot.value as? NSDictionary
            for (_, entry) in entries! {
                
                let lol = (entry as! NSDictionary)
                self.dateArray.append( lol.value(forKey: "time") as! String)
                self.emotionsArray.append(lol.value(forKey: "emotion") as! String)
                self.emojiArray.append(lol.value(forKey: "emoji") as! String)
            }
        
            print(self.dateArray)
            print(self.emotionsArray)
            self.animatedGradientView = AnimatedGradientView(frame: self.view.bounds)
            self.view.addSubview(self.animatedGradientView!)
            
            var tableRect = self.view.frame
            
            tableRect.origin.x += 15
            tableRect.size.width -= 30
            
            let tableView = UITableView(frame: tableRect, style: UITableViewStyle.grouped)
            tableView.delegate = self
            tableView.dataSource = self
            tableView.backgroundColor = UIColor.clear
            tableView.showsHorizontalScrollIndicator = false
            tableView.showsVerticalScrollIndicator = false
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "journalEntryTableViewCell")
            self.view.addSubview(tableView)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
            swipeLeft.direction = UISwipeGestureRecognizerDirection.left
            self.view.addGestureRecognizer(swipeLeft)
            
        })
        
        
        
       
        
        
        
    }
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.left:
                let transition = CATransition()
                transition.duration = 0.3
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
      
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "journalEntryTableViewCell", for: indexPath)
            lineChart = {
                let p = LineChartView(frame: cell.bounds)
                return p
            }()
            LineChartUpdate()
            cell.contentView.addSubview(lineChart)
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
    func LineChartUpdate () {
        var lineChartEntry = [ChartDataEntry]()
        lineChartEntry.append(ChartDataEntry(x:1.0, y:3.0))
        lineChartEntry.append(ChartDataEntry(x:2.0, y:6.0))
        lineChartEntry.append(ChartDataEntry(x:3.0, y:7.0))

        let line1 = LineChartDataSet(values:lineChartEntry, label:"Mood")
        let data = LineChartData()
        print(lineChartEntry)
        data.addDataSet(line1)
        print(lineChart)
        lineChart.data = data
        lineChart.chartDescription?.text = "My awesome chart"
        
        lineChart.notifyDataSetChanged()
    }
    
}
