import UIKit
import AudioToolbox

class MainViewController: UIViewController {

    @IBOutlet private(set) var rotateView: RotateView!
    @IBOutlet private(set) var numberLabels: [UILabel]!
    @IBOutlet private(set) var numbersView: UIView!
    @IBOutlet private(set) var scoreLabel: UILabel!
    @IBOutlet private(set) var markerLabels: [UIView]!
    
    var leftPanelAction: (()->())?
    var currentNumber: Int = 0
    var history = [HistoryItem]()
    
    fileprivate let colors = (exactly: #colorLiteral(red: 0.5803921569, green: 0.8784313725, blue: 0.2666666667, alpha: 1), exist: #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1), absent: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
    private var burglarEngine: BurglarEngine!
    private var isSlided: Bool = false
    private var score: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let s = "score".ud_object() as? String {
            self.score = s
        }
        else {
            self.score = "0"
        }
        
       let item = UIBarButtonItem(image: #imageLiteral(resourceName: "history"), style: .plain, target: self, action: #selector(historyPressed))
        self.navigationController?.navigationItem.leftBarButtonItem = item
        
        self.burglarEngine = BurglarEngine()
        
        self.rotateView.updateValue = { (value: Int) in
            SoundManager.playSound(success: self.burglarEngine.numbersForUnlock[self.currentNumber] == value)
            self.numberLabels[self.currentNumber].text = "\(value)"
        }
        
        self.rotateView.touchEnd = { [weak self] in
            if let s = self {
                s.currentNumber = s.currentNumber < 3 ?
                    s.currentNumber + 1 : 0
                
                if s.currentNumber == 0 {
                    s.checkNumbers()
                }
                s.updateCurrentMarker()
            }
        }
        
        SoundManager.setupSound(num: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.scoreLabel.text = self.score
        self.updateCurrentMarker()
    }
    
    //MARK:- Actions
  
    @IBAction func historyPressed(_ sender: Any) {
        if let action = self.leftPanelAction {
            self.history = self.burglarEngine.history
            action()
        }
    }
    
    @IBAction func numberButtonPressed(_ sender: UIButton) {
        self.currentNumber = sender.tag
        self.updateCurrentMarker()
    }
    
    @IBAction func checkPressed(_ sender: Any) {
        self.checkNumbers()
    }
    
    @IBAction func swipeRight(_ sender: Any) {
        print("swipe!!!")
    }
    
    //MARK:-
    
    private func reload() {
        self.burglarEngine.setupNumber()
        self.currentNumber = 0
        self.numberLabels.forEach { $0.text = "0" }
        SoundManager.setupSound(num: SoundManager.nextSoundNumber())
    }
    
    private func updateCurrentMarker() {
        self.markerLabels.forEach { $0.isHidden = true }
        self.markerLabels[self.currentNumber].isHidden = false
    }
    
    private func checkNumbers() {
        var numbers = [Int]()
        self.numberLabels.forEach({ (label: UILabel) in
            if let str = label.text {
                numbers.append(Int(str) ?? 0)
            }
            else {
                numbers.append(0)
            }
        })
        
        if self.burglarEngine.checkNumber(numbers: numbers) {
            Alert(alert: "win.message".localized, preferredStyle: UIAlertControllerStyle.alert, actions: "ok!").present(in: self)
            if let score = Int(self.score) {
                if score == 0 || self.burglarEngine.history.count < score {
                    self.score = "\(self.burglarEngine.history.count)"
                    self.score.ud_saveString(key: "score")
                    self.scoreLabel.text = self.score
                }
            }
            self.reload()
        }
        else {  
            self.numbersView.shake()
        }
    }
}
