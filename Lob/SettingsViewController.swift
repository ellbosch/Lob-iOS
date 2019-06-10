//
//  SettingsViewController.swift
//  Lob
//
//  Created by Elliot Boschwitz on 6/8/19.
//  Copyright © 2019 Elliot Boschwitz. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView?
    
    let rows = ["Terms of Service", "Privacy Policy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        
        // removes empty cells
        tableView?.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "SettingsTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? SettingsTableViewCell else {
            fatalError("The dequeued cell is not an instance of SettingsTableViewCell")
        }
        
        cell.label.text = rows[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // deselect row for formatting
        self.tableView?.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            guard let url = URL(string: "https://lob.tv/terms-of-service") else { return }
            UIApplication.shared.open(url)
        } else if indexPath.row == 1 {
            guard let url = URL(string: "https://lob.tv/privacy-policy") else { return }
            UIApplication.shared.open(url)
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
