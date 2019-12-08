//
//  QuizAPI.swift
//  QuizArcTouch
//
//  Created by Leonardo Bortolotti on 07/12/19.
//  Copyright © 2019 Leonardo Bortolotti. All rights reserved.
//

import Foundation

class QuizAPI {

    class func requestQuiz(completionHandler: @escaping (_ data: Data?) -> ()) {
        if let url = URL(string: Constants.kBASE_URL + "/quiz/1") {
            URLSession.shared.dataTask(with: url) { data, response, error in
                completionHandler(data)
            }.resume()
        }
    }

}
