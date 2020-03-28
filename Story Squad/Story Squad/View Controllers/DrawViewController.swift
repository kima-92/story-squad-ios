//
//  DrawViewController.swift
//  Story Squad
//
//  Created by Jonalynn Masters on 3/26/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    var networkingController: NetworkingController?
    var parentUser: Parent?
    var childUser: Child?
    
    var imagePicker: ImagePicker!
    var lastPoint = CGPoint.zero
    var color = UIColor.black
    
    var brushWidth: CGFloat = 10.0
    var opacity: CGFloat = 1.0
    var swiped = false
    
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var chooseFilesFromDeviceButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var selectedImage1Label: UILabel!
    @IBOutlet weak var selectAnImageLabel: UILabel!
    
    override func viewDidLoad() {        super.viewDidLoad()
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        
        self.hideKeyboardWhenTappedAround()
    }
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         guard let navController = segue.destination as? UINavigationController,
           let settingsController = navController.topViewController as? DrawSettingsViewController else {
             return
         }
         settingsController.delegate = self
         settingsController.brush = brushWidth
         settingsController.opacity = opacity
         
         var red: CGFloat = 0
         var green: CGFloat = 0
         var blue: CGFloat = 0
         color.getRed(&red, green: &green, blue: &blue, alpha: nil)
         settingsController.red = red
         settingsController.green = green
         settingsController.blue = blue
       }
    
    // MARK: - Actions
    
    @IBAction func submitButtonTapped(_ sender: Any) {
        submitDrawing()
    }
        
    @IBAction func chooseFilesFromDeviceButtonTapped(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    func updateViews() {
        promptLabel.layer.borderWidth = 7.0
        promptLabel.layer.cornerRadius = 10.0
        chooseFilesFromDeviceButton.layer.borderWidth = 3.0
        chooseFilesFromDeviceButton.layer.cornerRadius = 10.0
        submitButton.layer.borderWidth = 3.0
        submitButton.layer.cornerRadius = 10
    }
        
    func showDrawingSubmittedAlert() {
        
        let alert = UIAlertController(title: "Your Amazing Drawing has been Submitted!", message: "Thank you", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { (_) in
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showErrorAlert(errorTitle: String, errorMessage: String) {
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    func submitDrawing() {
        if let drawing = selectedImage1Label.text,
            !drawing.isEmpty {
            //
            //                   networkingController?.submitDrawing(child: Child, drawingImage: <#T##String#>, completion: <#T##(Result<String?, NetworkingError>) -> Void#>)
            //
            //                       do {
            //                           //swiftlint:disable:next redundant_discardable_let
            //                           let _ = try result.get()
            //
            //                           DispatchQueue.main.async {
            //                               self.showStorySubmittedAlert()
            //                           }
            //                       } catch {
            //                           DispatchQueue.main.async {
            //                               self.showErrorAlert(errorTitle: "Couldn't save your Story", errorMessage: " You can only submit one Story for this week. If you haven't submitted one yet, please try again")
            //                           }
            //                       }
            //                })
            showDrawingSubmittedAlert()
        } else {
            showErrorAlert(errorTitle: "No Drawing found", errorMessage: "Please upload an image before submitting")
            //               }
            //           }
            //    }
        }
    }
    
}
extension DrawViewController: ImagePickerDelegate {
    
    func didSelect(image: UIImage?) {
        let imageString = image?.description
        selectedImage1Label.text = imageString
    }
}
extension DrawViewController: DrawSettingsViewControllerDelegate {
  func settingsViewControllerFinished(_ settingsViewController: DrawSettingsViewController) {
    brushWidth = settingsViewController.brush
    opacity = settingsViewController.opacity
    color = UIColor(red: settingsViewController.red,
                    green: settingsViewController.green,
                    blue: settingsViewController.blue,
                    alpha: opacity)
    dismiss(animated: true)
  }
}
