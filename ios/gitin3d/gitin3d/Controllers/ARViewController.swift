import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var tableViewList:[String] = []
    
    var selectedProjectIndex: Int = -1
    var selectedCommit: Commit? = nil
    var branch: String = "master"
    var loadedSCNS = [String: URL]()
    var loadedSCN: URL?
    var compareSCN: URL?


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        
        // set the text from the data model
        cell.textLabel?.text = tableViewList[indexPath.row]
        
        return cell
    }
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch drawerTitle.text {
            case "Comments":
                break;
            case "Compare":
            
                let commitMessages = DataManager.shared.projects[selectedProjectIndex].commits.map{$0.message}
                let index = commitMessages.firstIndex(of: tableViewList[indexPath.row])
                let compareCommit = DataManager.shared.projects[selectedProjectIndex].commits[index ?? 0]
                closeDrawerBtn.sendActions(for: .touchUpInside)
                
                if let file = compareCommit.files.randomElement() {
                    self.compareSCN = self.loadedSCNS[compareCommit.id + "/" + file]
                    print("Compare scn is: ")
                    print(self.compareSCN)
                }
                
                break;
                
                
            break;
            case "Commits":
                let commitMessages = DataManager.shared.projects[selectedProjectIndex].commits.map{$0.message}
                let index = commitMessages.firstIndex(of: tableViewList[indexPath.row])
                selectedCommit = DataManager.shared.projects[selectedProjectIndex].commits[index ?? 0]
                closeDrawerBtn.sendActions(for: .touchUpInside)
                
                if let file = self.selectedCommit!.files.randomElement() {
                    self.loadedSCN = self.loadedSCNS[self.selectedCommit!.id + "/" + file]
                    print("Loaded scn is: ")
                    print(self.loadedSCN)
                }
                
                break;
            case "Files":
                let file = tableViewList[indexPath.row]
                let id = selectedCommit!.id
                
                loadedSCN = loadedSCNS[id + "/" + file]
                
                closeDrawerBtn.sendActions(for: .touchUpInside)
                break;
            default:
                print("hello world!")
        }
        tableView.reloadData()
    }
    

    @IBOutlet weak var drawer: UIView!
    @IBOutlet weak var drawerTitle: UILabel!
    
    var drawerOpen = false
    var plane_only = true
    var currentAngleY: Float = 0.0

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func surfaceAirSegmentedControl(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            plane_only = true
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                
                if node.name == "air" {
                    node.removeFromParentNode()
                }
                else {
//                    node.isHidden = false
                }
            
            }
        }
            
        else {
            
            plane_only = false
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                
                if node.name == "surface" {
                    node.removeFromParentNode()
                }
                else {
//                    node.isHidden = true
                }
            }
        }
    }
    
    @IBOutlet weak var commentInput: UITextField!
    
    @IBOutlet weak var addCommentButton: UIButton!
    @IBAction func addCommentButtonOnClick(_ sender: Any) {
        compareSCN = nil
        
        tableViewList.append(commentInput.text ?? "")
        selectedCommit!.comments.append(commentInput.text ?? "")
        
        if let comment = commentInput.text {
            postComment(comment: comment)
        }
        commentInput.text = ""
        
        tableView.reloadData()
    }
    
    func postComment(comment: String) {
        let encoded = comment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
        let path = "http://cd01adcc7b24.ngrok.io:80/project/" + DataManager.shared.projects[selectedProjectIndex].id + "/comment/" + selectedCommit!.id + "?comment=" + encoded!
        
        let url = URL(string: path)!
        URLSession.shared.dataTask(with: URLRequest(url: url)).resume()
    }

    @IBAction func annotationButton(_ sender: Any) {
        compareSCN = nil

        if !drawerOpen {
            drawer.isHidden = false
            drawerTitle.text = "Comments"
            commentInput.isHidden = false;
            addCommentButton.isHidden = false;
            tableViewList = selectedCommit!.comments
            tableView.reloadData()
        }
    }
    @IBAction func compareButton(_ sender: Any) {
        compareSCN = nil

        if !drawerOpen {
            drawer.isHidden = false
            drawerTitle.text = "Compare"
            commentInput.isHidden = true;
            addCommentButton.isHidden = true;
            
            let project = DataManager.shared.projects[selectedProjectIndex]
            
            let commits = CommitCalculator.getCommitsOfBranch(project: project, branch: branch)
            
            tableViewList = commits.map{$0.message}
            tableView.reloadData()
        }
    }
    
    @IBAction func commitButton(_ sender: Any) {
        compareSCN = nil

        if !drawerOpen {
            drawer.isHidden = false
            drawerTitle.text = "Commits"
            commentInput.isHidden = true;
            addCommentButton.isHidden = true;
            
            let project = DataManager.shared.projects[selectedProjectIndex]
            
            let commits = CommitCalculator.getCommitsOfBranch(project: project, branch: branch)
            
            tableViewList = commits.map{$0.message}
            tableView.reloadData()
        }
    }
    
    @IBAction func filesButton(_ sender: Any) {
        compareSCN = nil

        if !drawerOpen {
            drawer.isHidden = false
            drawerTitle.text = "Files"
            commentInput.isHidden = true;
            addCommentButton.isHidden = true;
            tableViewList = selectedCommit!.files
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !drawerOpen {
            drawer.isHidden = true
        }
        drawer.alpha = 0.8
//        addAnnotation()
        commentInput.isHidden = true;
        addCommentButton.isHidden = true;
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        
        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self
        
        tableViewList = DataManager.shared.projects.map{$0.name}
        
        let project = DataManager.shared.projects[selectedProjectIndex]
        
        let taskGroup = DispatchGroup()
        
        self.showSpinner(onView: self.view)
        
        for commit in project.commits {
            let basePath = "http://cd01adcc7b24.ngrok.io:80/" + project.id + "/" + commit.id + "/"
            
            for fileName in commit.files {
                loadSCN(fileUrl: basePath + fileName, commitId: commit.id, file: fileName, group: taskGroup)
            }
        }

        
        taskGroup.notify(queue: DispatchQueue.main) {
            
            if let file = self.selectedCommit!.files.randomElement() {
                self.loadedSCN = self.loadedSCNS[self.selectedCommit!.id + "/" + file]
                print("Loaded scn is: ")
                print(self.loadedSCN)
            }
            
            self.removeSpinner()
        }
        
    }
    
    func loadSCN(fileUrl: String, commitId: String, file: String, group: DispatchGroup) {
        if let url = URL(string: fileUrl) {
            group.enter()
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 10.0
            sessionConfig.timeoutIntervalForResource = 20.0
            let session = URLSession(configuration: sessionConfig)
            
            let request = URLRequest(url: url)
            
            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if(tempLocalUrl != nil) {
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        print("Successfully downloaded. Status code: \(statusCode)")
                    }
                    
                    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                    let documentsDirectory = paths[0]
                    
                    do {
                        try FileManager.default.createDirectory(atPath: documentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error)
                    }
                    
                    let localUrl = documentsDirectory.appendingPathComponent(tempLocalUrl!.lastPathComponent)
                    
                    
                    let local_url = localUrl
                        .deletingPathExtension()
                        .appendingPathExtension("scn")
                    
                    try? FileManager.default.removeItem(at: local_url)
                    
                    do {
                        print(tempLocalUrl,local_url)
                        try FileManager.default.moveItem(at: tempLocalUrl!, to: local_url)
                        self.loadedSCNS[commitId + "/" + file] = (local_url)
                    } catch {
                        print("failed to copy item")
                        print(error)
                    }
                    
                } else {
                    print("Failed")
                }
                
                defer {
                    group.leave()
                }
            }
            
            task.resume()
        } else {
            print("No URL")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setUpSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.delegate = self
        sceneView.debugOptions = [.showFeaturePoints]
        
        configureLighting()
        addTapGestureToSceneView()
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    @IBAction func closeDrawerButton(_ sender: Any) {
        compareSCN = nil
        drawerOpen = false
        drawer.isHidden = true
    }
    
    @IBOutlet weak var closeDrawerBtn: UIButton!
    
    // Anywhere in the air
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !plane_only {

            guard let touch = touches.first else { return }
            let result = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
            guard let hitResult = result.last else { return }
            let hitTransform = SCNMatrix4.init(hitResult.worldTransform)
            let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
            addObject(position: hitVector)
        }
    }
    
    func addObject(position: SCNVector3){
    
        print(loadedSCNS)
        if (!loadedSCNS.isEmpty){
            
            if let object_path = loadedSCN {
            //        print(object_url)
            //        let object_path =  "art.scnassets/" + "model" + ".scn"
                do {
                let objectScene = try SCNScene.init(url: object_path , options: nil)
                    
                    
                let objectNode = objectScene.rootNode.childNodes[0]
                objectNode.scale = SCNVector3(x: 0.00254, y: 0.00254, z: 0.00254)
                objectNode.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
                //        guard let objectScene = try? SCNScene(url: object_path),
                //            let objectNode = objectScene.rootNode.childNode(withName: object, recursively: false)
                //            else { return }
                
                objectNode.position = position
                
                //Lighting
                let spotLight = SCNLight()
                spotLight.type = SCNLight.LightType.probe
                spotLight.spotInnerAngle = 30.0
                spotLight.spotOuterAngle = 80.0
                spotLight.castsShadow = true
                objectNode.light = spotLight
                objectNode.name = "air"
                
                
                //Add max 1 object
                let childNodes = sceneView.scene.rootNode.childNodes
                if (childNodes.isEmpty){
                    sceneView.scene.rootNode.addChildNode(objectNode)
                } else{
                    sceneView.scene.rootNode.replaceChildNode(childNodes[0], with: objectNode)
                }
            } catch {
                print("failed to make obj scene")
                print(error)
            }
            
        }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let width = CGFloat(planeAnchor.extent.x)
            let height = CGFloat(planeAnchor.extent.z)
            let plane = SCNPlane(width: width, height: height)
            
            plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
            
            let planeNode = SCNNode(geometry: plane)
            
            let x = CGFloat(planeAnchor.center.x)
            let y = CGFloat(planeAnchor.center.y)
            let z = CGFloat(planeAnchor.center.z)
            planeNode.position = SCNVector3(x,y,z)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
            guard let planeAnchor = anchor as?  ARPlaneAnchor,
                let planeNode = node.childNodes.first,
                let plane = planeNode.geometry as? SCNPlane
                else { return }
            
            let width = CGFloat(planeAnchor.extent.x)
            let height = CGFloat(planeAnchor.extent.z)
            plane.width = width
            plane.height = height
            
            let x = CGFloat(planeAnchor.center.x)
            let y = CGFloat(planeAnchor.center.y)
            let z = CGFloat(planeAnchor.center.z)
            planeNode.position = SCNVector3(x, y, z)
        
    }
    
    func setMaterialColor(node: SCNNode, color: UIColor) {
        if node.geometry != nil {
            let original = node.geometry!.firstMaterial

            let copy = original?.copy() as? SCNMaterial
            copy?.diffuse.contents = color
            node.geometry!.firstMaterial = copy
            
            return
        }
        for c in node.childNodes {
            setMaterialColor(node: c, color: color)
        }
    }
    
    
    @objc func addModelToSceneViewSurface(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        if plane_only {
            let tapLocation = recognizer.location(in: sceneView)
            var hitTestResults = sceneView.hitTest(tapLocation, types: [.featurePoint,.existingPlaneUsingExtent])
            if (plane_only){
                hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            }
            
            guard let hitTestResult = hitTestResults.first else { return }
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y
            let z = translation.z
            if (loadedSCN != nil){
                let object_path = loadedSCN!
                
                do {
                    var options = [SCNSceneSource.LoadingOption : Any]()
                    options[SCNSceneSource.LoadingOption.convertToYUp] = true
                    let objectScene = try SCNScene.init(url: object_path, options: options)
                    
                    var nodes = [SCNNode]()
                    
                    let objectNode = objectScene.rootNode.childNodes[0]
                    
                    nodes.append(objectNode)
                    
                    if let compareObj = compareSCN {
                        let compareScene = try? SCNScene.init(url: compareObj, options: options)
                        if let node = compareScene?.rootNode.childNodes[0] {
                            nodes.append(node)
                        }
                    }
                    
//                    objectNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//
                    
                    
            
                    var opacity = 1.0
                    
                    if nodes.count > 1 {
                        setMaterialColor(node: nodes[0], color: UIColor.red)
                        setMaterialColor(node: nodes[1], color: UIColor.green)
                        opacity = 0.8
                    }
                    
                    var shift = 0.0
                    for node in nodes {
                        node.scale = SCNVector3(x: 0.00254, y: 0.00254, z: 0.00254)
                        node.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
                        let xgay = x + Float(shift)
                        let ygay = y + Float(shift)
                        let zgay = z - Float(shift)
                        node.position = SCNVector3(x: xgay, y: ygay, z: zgay)
                        node.name = "surface"
                        node.opacity = CGFloat(opacity)
                        shift += 0.006
                    }
                    
                    let orig = nodes[0].scale
                    nodes[0].scale = SCNVector3(x: 1.1 * orig.x, y: 1.1 * orig.y, z: 1.1 * orig.z)
                    
                    var root = sceneView.scene.rootNode
                    root.enumerateChildNodes { (node, b) in
                        if node.name == "surface" {
                            node.removeFromParentNode()
                        }
                    }
                    
                    for node in nodes {
                        print(nodes.count)
                        sceneView.scene.rootNode.addChildNode(node)
                    }

                } catch {
                    print("failed to make obj scene")
                    print(error)
                }
                
            }
        }

    }
    
    func addTapGestureToSceneView() {
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ARViewController.scaleObject(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)

        if plane_only {
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ARViewController.addModelToSceneViewSurface(withGestureRecognizer:)))
            sceneView.addGestureRecognizer(tapGestureRecognizer)
            
        }
    }


    
    @objc func scaleObject(withGestureRecognizer gesture: UIPinchGestureRecognizer) {
        let nodes = sceneView.scene.rootNode.childNodes
        print(gesture.scale)

        for nodeToScale in nodes {
            let pinchScaleX: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.x))
            let pinchScaleY: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.y))
            let pinchScaleZ: CGFloat = gesture.scale * CGFloat((nodeToScale.scale.z))
            nodeToScale.scale = SCNVector3Make(Float(pinchScaleX), Float(pinchScaleY), Float(pinchScaleZ))
            gesture.scale = 1
        }


    }
}


extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}
