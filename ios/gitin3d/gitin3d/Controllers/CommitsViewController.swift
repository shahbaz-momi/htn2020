import UIKit

class CommitsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return branches.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return branches[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        currentBranch = branches[row]
        
        let project = DataManager.shared.projects[selectedProjectIndex]
        currentCommits = CommitCalculator.getCommitsOfBranch(project: project, branch: currentBranch)
        
        self.commitTable.reloadData()
        self.view.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ar" {
            let destinationViewController = segue.destination as! ARViewController

            destinationViewController.selectedProjectIndex = selectedProjectIndex as? Int ?? -1
            destinationViewController.selectedCommit = sender as? Commit
            destinationViewController.branch = currentBranch

        }
    }
    
    
    var currentBranch = "master"
    var branches = ["master"]
    var currentCommits: [Commit] = [Commit]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCommits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.commitTable.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = currentCommits[indexPath.row].message
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "ar", sender: currentCommits[indexPath.row] )
    }

    
    
    @IBOutlet weak var branchPicker: UIPickerView!
    var selectedProjectIndex: Int = -1

    @IBOutlet weak var commitTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let project = DataManager.shared.projects[selectedProjectIndex]
        currentCommits = CommitCalculator.getCommitsOfBranch(project: project, branch: currentBranch)
        branches = CommitCalculator.getBranches(project: project)
        
        commitTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        commitTable.delegate = self
        commitTable.dataSource = self
        // Do any additional setup after loading the view.
        
        branchPicker.delegate = self
        branchPicker.dataSource = self

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
