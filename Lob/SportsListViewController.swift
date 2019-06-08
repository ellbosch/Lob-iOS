//
//  SportsListViewController.swift
//  The Lob
//
//  Created by Elliot Boschwitz on 12/27/18.
//  Copyright © 2018 Elliot Boschwitz. All rights reserved.
//

import UIKit

class SportsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarControllerDelegate {
    @IBOutlet weak var tableView: UITableView?
    
    var sports: [(String, UIImage?)] = [("NBA", UIImage(named: "basketball")),
                                        ("NFL", UIImage(named: "footballAmerican")),
                                        ("MLB", UIImage(named: "baseball"))]
    
    var legal: [String] = ["Terms of Service", "Privacy Policy", "DMCA"]
    
    // ensures status bar is visible on this view
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instantiate tableview
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()
        
        // removes empty cells
        tableView?.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {        
        // set delegate to tabBarController here so that it changes to this VC (in case delegate is still set from another VC)
        tabBarController?.delegate = self

        // if we're in hot posts view: make status bar solid white
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = nil
    }
    
    // delegate class for tab bar forces view to go to root when channel tab selected
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let secondVC = tabBarController.viewControllers?[1] as? UINavigationController
        secondVC?.popToRootViewController(animated: false)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return sports.count
        case 1:
            return legal.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: SportsTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SportsTableViewCell", for: indexPath) as? SportsTableViewCell else {
            fatalError("The dequeued cell is not an instance of SportsTableViewCell")
        }
        switch indexPath.section {
        case 0:
            let sport = sports[indexPath.row]
            cell.sportsLabel?.text = sport.0
            cell.iconLabel?.image = sport.1
        case 1:
            cell.sportsLabel?.text = legal[indexPath.row]
        default:
            break
        }
        return cell
    }
    
    // "deselects" cell for formatting
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? FeedViewController,
                let selectedRow = tableView?.indexPathForSelectedRow else { return }
        
        let sport = self.sports[selectedRow.row]
        
        // set page sport league variable and title
        destinationVC.title = sport.0

        switch sport.0 {
        case "NBA":
            destinationVC.league = "nba"
        case "Soccer - All Leagues":
            destinationVC.league = "soccer"
        case "MLB":
            destinationVC.league = "baseball"
        case "NFL":
            destinationVC.league = "nfl"
        default:
            break    // loads hot posts
        }
    }
}
