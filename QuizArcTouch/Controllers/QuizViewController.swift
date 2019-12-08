//
//  ViewController.swift
//  QuizArcTouch
//
//  Created by Leonardo Bortolotti on 07/12/19.
//  Copyright © 2019 Leonardo Bortolotti. All rights reserved.
//

import UIKit

class QuizViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    let kTIME_TO_ANSWER = 300 // 300 seconds = 5 minutes
    let kANSWER_CELL = "AnswerCell"
    let kCORNER_RADIUS: CGFloat = 10
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var answerTextField: UITextField!
    @IBOutlet weak var answersTableView: UITableView!
    @IBOutlet weak var answersCountLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private var keywordsSet: NSMutableSet!
    private var answersArray: [String] = []
    private var time: Int!
    private var timer: Timer!
    private var isPlaying = false
    private var quiz: Quiz!
    private var loadingView: LoadingView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        titleLabel.isHidden = true
        answerTextField.isHidden = true
        answersTableView.isHidden = true
        
        answersTableView.delegate = self
        answersTableView.dataSource = self
        answerTextField.delegate = self
        
        answerTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0) // Add padding to the left of text
        answerTextField.layer.cornerRadius = kCORNER_RADIUS
        startButton.layer.cornerRadius = kCORNER_RADIUS
        
        answersTableView.tableFooterView = UIView() // Remove the unnecessary lines of TableView
        
        answersCountLabel.text = "00/50"
        time = kTIME_TO_ANSWER
        updateTime()
        
        loadingView = LoadingView(frame: view.frame)
        view.addSubview(loadingView)
        
        requestQuiz()
    }
    
    // MARK: - Button Pressed

    @IBAction func startButtonPressed(_ sender: UIButton) {
        if !isPlaying {
            start()
        }
        else {
            reset()
        }
        isPlaying = !isPlaying
    }
    
    // MARK: - Helper Methods
    
    private func requestQuiz() {
        QuizAPI.requestQuiz { (data) in
            if let data = data {
                do {
                    self.quiz = try JSONDecoder().decode(Quiz.self, from: data)
                    self.keywordsSet = NSMutableSet(array: self.quiz.answer ?? [])
                    DispatchQueue.main.async {
                        self.setupUserInterface()
                    }
                } catch let error {
                    print(error)
                }
            }
            else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: NSLocalizedString("Connection error", comment: ""),
                                                  message: NSLocalizedString("Try again later.", comment: ""),
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            DispatchQueue.main.async {
                self.loadingView.removeFromSuperview()
            }
        }
    }
    
    private func setupUserInterface() {
        // Show layout when finishes loading
        titleLabel.isHidden = false
        answerTextField.isHidden = false
        answersTableView.isHidden = false
        
        titleLabel.text = quiz.question
        updateAnswersCount()
    }
    
    private func start() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCountdown), userInfo: nil, repeats: true)
        startButton.setTitle(NSLocalizedString("Reset", comment: ""), for: .normal)
    }
    
    private func reset() {
        timer.invalidate()
        time = kTIME_TO_ANSWER
        updateTime()
        answersArray = []
        updateAnswersCount()
        startButton.setTitle(NSLocalizedString("Start", comment: ""), for: .normal)
        keywordsSet = NSMutableSet(array: self.quiz.answer ?? [])
        answerTextField.text = ""
        answersTableView.reloadData()
    }
    
    @objc private func timerCountdown() {
        time -= 1
        updateTime()
        
        if time <= 0 {
            isPlaying = !isPlaying
            timer.invalidate()
            let alert = UIAlertController(title: NSLocalizedString("Time finished", comment: ""),
                                          message: .init(format: NSLocalizedString("LoseTextAlert", comment: ""), answersArray.count, quiz.answer?.count ?? 0),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""),
                                          style: .default, handler: { (_) in
                self.reset()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateTime() {
        let minutes = time / 60
        let seconds = time - minutes * 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateAnswersCount() {
        answersCountLabel.text = String(format: "%02d/%02d", answersArray.count, (quiz.answer ?? []).count)
    }
    
    private func checkAnswer(string: String) -> Bool {
        let answerString = string.lowercased()
        if keywordsSet.contains(answerString) {
            answersArray.append(answerString.prefix(1).capitalized + answerString.dropFirst()) // Format with only first letter capitalized
            keywordsSet.remove(answerString) // Remove the object from set, in the case of showing the remaining words to the user in the future
            answerTextField.text = ""
            
            // Insert rows for a better performance than reloadData()
            answersTableView.beginUpdates()
            answersTableView.insertRows(at: [IndexPath(row: answersArray.count - 1, section: 0)], with: .fade)
            answersTableView.endUpdates()
            
            updateAnswersCount()
            checkWin()
            
            return true
        }
        return false
    }
    
    private func checkWin() {
        if answersArray.count == quiz.answer?.count {
            isPlaying = !isPlaying
            timer.invalidate()
            let alert = UIAlertController(title: NSLocalizedString("Congratulations", comment: ""),
                                          message: NSLocalizedString("WinTextAlert", comment: ""),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Play Again", comment: ""),
                                          style: .default, handler: { (_) in
                self.reset()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Keyboard
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.view.frame.size.height = UIScreen.main.bounds.height - keyboardSize.height
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        self.view.frame = UIScreen.main.bounds
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return answersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kANSWER_CELL, for: indexPath)
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.textLabel?.text = answersArray[indexPath.row]
        return cell
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !isPlaying { return false }
        if checkAnswer(string: (textField.text ?? "") + string) { return false }
        return true
    }
    
}

