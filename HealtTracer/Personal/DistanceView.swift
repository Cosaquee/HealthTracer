import Foundation
import UIKit
import RealmSwift

class DistanceView: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var distanceMadeLabel: UILabel!
    @IBOutlet weak var distanceGoalLabel: UILabel!
    @IBOutlet weak var distanceTextField: UITextField!
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBAction func editGoal(_ sender: Any) {
        print("Edit")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(DistanceGoal.self))
            let distanceGoal = DistanceGoal()
            distanceGoal.goal = Int(distanceTextField.text!)!
            realm.add(distanceGoal)
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        self.distanceTextField.delegate = self
        
        let distances = realm.objects(DistanceGoal.self)

        var goal = 4
        if let distanceGoal = distances.first {
            goal = distanceGoal.goal
        } else {
            print("Goal not set")
        }
    
        let hkm = HealtKitManager()
        
        hkm.readDistance(result: { (weight, _) in
            DispatchQueue.main.async {
                self.distanceMadeLabel.text = "\(Int(weight))km"
                self.distanceTextField.text = "\(goal)"
                
                if (weight < Double(goal)) {
                    self.statusImage.image = UIImage(named: "sad")
                } else {
                    self.statusImage.image = UIImage(named: "smile")
                }
            }
        })
    }
}
