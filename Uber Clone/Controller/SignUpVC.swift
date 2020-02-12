//
//  SignUpVC.swift
//  Uber Clone
//
//  Created by Shishir Ahmed on 17/1/20.
//  Copyright © 2020 Shishir Ahmed. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import GeoFire

class SignUpVC: UIViewController {

    //Mark:: Properties
    private var location = LocationHandler.shared.locationManager.location
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    
    private lazy var emailContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var fullnameContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullnameTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var passwordContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private lazy var accountTypeContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x"),
                                               segmentedControl: accountTypeSegmentedControl)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email",
                                       isSecureTextEntry: false)
    }()
    
    private let fullnameTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Fullname",
                                       isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Password",
                                       isSecureTextEntry: true)
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Rider", "Driver"])
        sc.backgroundColor = .backgroundColor
        sc.tintColor = UIColor(white: 1, alpha: 0.87)
        sc.selectedSegmentIndex = 0
        return sc
    }()
    
    private let signUpButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let alreadyHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign In", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
        
        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        //Looks for single or multiple taps.
        let keyTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(keyTap)
    }
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //MARK:: Setup Views
    
    func configureUI(){
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: nil, bottom: nil, trailing: nil, padding: .init(top: 20, left: 0, bottom: 0, right: 0), size: .zero)
        titleLabel.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView,
                                                   fullnameContainerView,
                                                   passwordContainerView,
                                                   accountTypeContainerView,
                                                   signUpButton
                                                   ])
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.spacing = 24
        
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 40, left: 16, bottom: 0, right: 16))
        
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(top: nil, leading: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 10, right: 0), size: .init(width: 280, height: 32))
    }
    
    //MARK:: Custom Selectors
    
    @objc func handleShowLogin(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleSignUp(){
        
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullname = fullnameTextField.text else { return }
        let accountTypeIndex = accountTypeSegmentedControl.selectedSegmentIndex
        
        Auth.auth().createUser(withEmail: email, password: password) { ( result, error) in
            if let error = error{
                print("Failed to register user with error \(error)")
            }
            
            guard let uid = result?.user.uid else {return}
            let values = ["email": email,
                          "fullname": fullname,
                          "accountType": accountTypeIndex ] as [String: Any]
            
            if accountTypeIndex == 1 {
                let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
                guard let location = self.location else { return }
                
                geoFire.setLocation(location, forKey: uid) { (error) in
                    self.uploadUserDataAndShowHomeController(uid: uid, values: values)
                }
            }
            
            self.uploadUserDataAndShowHomeController(uid: uid, values: values)
        }
        
    }
    
    func uploadUserDataAndShowHomeController(uid: String, values: [String: Any]){
        REF_USERS.child(uid).updateChildValues(values) { (error, ref) in
            guard let controller = UIApplication.shared.keyWindow?.rootViewController as? HomeVC
                else{return}
            controller.configure()
            self.dismiss(animated: true, completion: nil)
        }
    }
}
