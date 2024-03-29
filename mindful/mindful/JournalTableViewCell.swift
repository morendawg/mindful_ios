//
//  JournalTableViewCell.swift
//  mindful
//
//  Created by Daniel Moreno on 2/22/18.
//  Copyright © 2018 seniordesign. All rights reserved.
//

import UIKit

class JournalTableViewCell: UITableViewCell {
    
    var dateLabel: UILabel!
    var contextLabel: UILabel!
    var emotionLabel: UILabel!
    var emojiLabel: UILabel!
    var transcriptionPreviewLabel: UILabel!
    var seeMoreButton : UIButton!
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:)")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let gap : CGFloat = 85
        let labelHeight: CGFloat = 30
        let labelWidth: CGFloat = 300
        let emojiSize = 60.0
        
        emojiLabel = UILabel()
        emojiLabel.font = emojiLabel.font.withSize(55)
        emojiLabel.frame = CGRect(x:10, y: 10, width: emojiSize, height: emojiSize)
        emojiLabel.text = "😏"
        contentView.addSubview(emojiLabel)
        
        dateLabel = UILabel()
        dateLabel.frame = CGRect(x: gap, y: 10, width: labelWidth, height: labelHeight)
        dateLabel.text = "February 6, 2018"
        contentView.addSubview(dateLabel)
        
        contextLabel = UILabel()
        contextLabel.font = contextLabel.font.withSize(12)
        contextLabel.frame = CGRect(x: gap, y: dateLabel.frame.height+2, width: labelWidth, height: labelHeight)
        contextLabel.text = "Philadelphia, PA | Mostly cloudy (32°)"
        contentView.addSubview(contextLabel)
        
        emotionLabel = UILabel()
        emotionLabel.font = UIFont.italicSystemFont(ofSize: 12.0)
        emotionLabel.frame = CGRect(x: gap, y: contextLabel.frame.height+20, width: labelWidth, height: labelHeight)
        emotionLabel.text = "angry, sad"
        contentView.addSubview(emotionLabel)
        
        seeMoreButton = UIButton()
        seeMoreButton.imageView?.contentMode = UIViewContentMode.center
        seeMoreButton.frame = CGRect(x : 350-emojiSize, y : Double(contentView.center.y)-10, width: emojiSize, height: emojiSize)
        seeMoreButton.setImage(#imageLiteral(resourceName: "Right Arrow Icon"), for: UIControlState.normal)
        contentView.addSubview(seeMoreButton)
        
        
    }
    
}

