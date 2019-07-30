//
//  SportsTableViewCell.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 6/10/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit

class SportsTableViewCell: UITableViewCell {
    @IBOutlet weak var sportsLabel: UILabel?
    @IBOutlet weak var iconLabel: UIImageView?
    
    var sport: Sport? {
        didSet {
            setupView()
        }
    }
    
    func setupView() {
        if let sport = self.sport {
            self.sportsLabel?.text = sport.name
            self.iconLabel?.image = UIImage(named: sport.iconLabel)
        } else {
            self.sportsLabel?.text = "Settings"
            self.iconLabel?.image = UIImage(named: "settings")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
