//
//  SVPinView.swift
//  SVPinView
//
//  Created on 10/10/17.
//

import UIKit

@objc
public enum SVPinViewStyle: Int {
    case none = 0
    case underline
    case box
}

@objc
public enum SVPinViewDeleteButtonAction: Int {
    /// Deletes the contents of the current field and moves the cursor to the previous field.
    case deleteCurrentAndMoveToPrevious = 0
    
    /// Simply deletes the content of the current field without moving the cursor.
    /// If there is no value in the field, the cursor moves to the previous field.
    case deleteCurrent
    
    /// Moves the cursor to the previous field and delets the contents.
    /// When any field is focused, its contents are deleted.
    case moveToPreviousAndDelete
}

private class SVPinViewFlowLayout: UICollectionViewFlowLayout {
    override var developmentLayoutDirection: UIUserInterfaceLayoutDirection { return .leftToRight }
    override var flipsHorizontallyInOppositeLayoutDirection: Bool { return true }
}

@objcMembers
open class SVPinView: UIView {
    let collectionView: UICollectionView
    
    // MARK: - Initializer
    public override init(frame: CGRect) {
       // Setup flow layout
       let layout = UICollectionViewFlowLayout()
       layout.scrollDirection = .horizontal
       layout.itemSize = CGSize(width: 50, height: 50)
       layout.minimumLineSpacing = 0
       layout.minimumInteritemSpacing = 0
       layout.sectionInset = .zero

       // Setup collection view
       collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
       collectionView.translatesAutoresizingMaskIntoConstraints = false
       collectionView.backgroundColor = UIColor.clear
       collectionView.showsHorizontalScrollIndicator = true
       collectionView.showsVerticalScrollIndicator = false
       // Optionally set scrollIndicatorInsets if needed:
       // collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

       super.init(frame: frame)
       setupViews()
    }

    required public init?(coder: NSCoder) {
       // Setup flow layout
       let layout = UICollectionViewFlowLayout()
       layout.scrollDirection = .horizontal
       layout.itemSize = CGSize(width: 50, height: 50)
       layout.minimumLineSpacing = 0
       layout.minimumInteritemSpacing = 0
       layout.sectionInset = .zero

       // Setup collection view
       collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
       collectionView.translatesAutoresizingMaskIntoConstraints = false
       collectionView.backgroundColor = UIColor.clear
       collectionView.showsHorizontalScrollIndicator = true
       collectionView.showsVerticalScrollIndicator = false
       // Optionally set scrollIndicatorInsets if needed:
       // collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

       super.init(coder: coder)
       setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        collectionView.register(SVPinCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        flowLayout.scrollDirection = .vertical
        collectionView.isScrollEnabled = false
    }

    fileprivate var flowLayout: UICollectionViewFlowLayout {
        let layout = SVPinViewFlowLayout()
        layout.minimumInteritemSpacing = interSpace
        layout.minimumLineSpacing = 0
        self.collectionView.collectionViewLayout = layout
        return self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    fileprivate var reuseIdentifier = "SVPinCell"
    fileprivate var isLoading = true
    fileprivate var password = [String]()
    
    // MARK: - Public Properties -
    public var pinLength: Int = 5
    public var secureCharacter: String = "\u{25CF}"
    public var interSpace: CGFloat = 5
    public var textColor: UIColor = UIColor.black
    public var shouldSecureText: Bool = true
    public var secureTextDelay: Int = 500
    public var allowsWhitespaces: Bool = true
    public var placeholder: String = ""
    
    public var borderLineColor: UIColor = UIColor.black
    public var activeBorderLineColor: UIColor = UIColor.black
    public var errorBorderLineColor: UIColor = UIColor.red

    public var borderLineThickness: CGFloat = 2
    public var activeBorderLineThickness: CGFloat = 4
    
    public var fieldBackgroundColor: UIColor = UIColor.clear
    public var activeFieldBackgroundColor: UIColor = UIColor.clear
    
    public var fieldCornerRadius: CGFloat = 0
    public var activeFieldCornerRadius: CGFloat = 0
    
    public var style: SVPinViewStyle = .underline
    public var deleteButtonAction: SVPinViewDeleteButtonAction = .deleteCurrentAndMoveToPrevious
    
    public var font: UIFont = UIFont.systemFont(ofSize: 15)
    public var keyboardType: UIKeyboardType = UIKeyboardType.phonePad
    public var keyboardAppearance: UIKeyboardAppearance = .default
    public var becomeFirstResponderAtIndex: Int? = nil
    public var isContentTypeOneTimeCode: Bool = false
    public var shouldDismissKeyboardOnEmptyFirstField: Bool = false
    public var pinInputAccessoryView: UIView? {
        didSet { refreshPinView() }
    }
    
    public var isError: Bool = false {
        didSet {
            reloadStyles()
        }
    }
    public var didFinishCallback: ((String)->())?
    public var didChangeCallback: ((String)->())?
    public var didReceiveError: ((Error)->())?
    
    // MARK: - Private methods -
    @objc fileprivate func textFieldDidChange(_ textField: UITextField) {
        let nextTag = textField.tag
        let index = nextTag - 100
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index - 1, section: 0)) as? SVPinCell else {
            showPinError(error: "ERR-100: Type Mismatch")
            return
        }
        
        let placeholderLabel = cell.placeholderLabel
        
        // ensure single character in text box and trim spaces
        if textField.text?.count ?? 0 > 1 {
            textField.text?.removeFirst()
            textField.text = { () -> String in
                let text = textField.text ?? ""
                return String(text[..<text.index((text.startIndex), offsetBy: 1)])
            }()
        }
        
        let isBackSpace = { () -> Bool in
            guard let char = textField.text?.cString(using: String.Encoding.utf8) else { return false }
            return strcmp(char, "\\b") == -92
        }
        
        if !self.allowsWhitespaces && !isBackSpace() && textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            return
        }
        
        // if entered text is a backspace - do nothing; else - move to next field
        // backspace logic handled in SVPinField
        let nextIndex = isBackSpace() ? index - 1 : index
        
        if let cell = collectionView.cellForItem(at: .init(item: nextIndex, section: 0)) as? SVPinCell {
            cell.pinField.becomeFirstResponder()
        } else {
            if index == 1 && shouldDismissKeyboardOnEmptyFirstField {
                textField.resignFirstResponder()
            } else if index > 1 { textField.resignFirstResponder() }
        }
        
        // activate the placeholder if textField empty
        placeholderLabel.isHidden = !(textField.text?.isEmpty ?? true)
        
        // secure text after a bit
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(secureTextDelay), execute: {
            if !(textField.text?.isEmpty ?? true) {
                placeholderLabel.isHidden = true
                if self.shouldSecureText { textField.text = self.secureCharacter }
            }
        })
        
        // store text
        let text =  textField.text ?? ""
        let passwordIndex = index - 1
        if password.count > (passwordIndex) {
            // delete if space
            password[passwordIndex] = text
        } else {
            password.append(text)
        }
        validateAndSendCallback()
    }
    
    fileprivate func validateAndSendCallback() {
        didChangeCallback?(password.joined())
        
        let pin = getPin()
        guard !pin.isEmpty else { return }
        didFinishCallback?(pin)
    }
    
    fileprivate func setPlaceholder() {
        for (index, char) in placeholder.enumerated() {
            guard index < pinLength else { return }
            
            if let placeholderLabel = (collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? SVPinCell)?.placeholderLabel {
                placeholderLabel.text = String(char)
            } else { showPinError(error: "ERR-102: Type Mismatch") }
        }
    }
    
    fileprivate func stylePinField(containerView: UIView, underLine: UIView, isActive: Bool) {
        
        containerView.backgroundColor = isActive ? activeFieldBackgroundColor : fieldBackgroundColor
        containerView.layer.cornerRadius = isActive ? activeFieldCornerRadius : fieldCornerRadius
        
        func setupUnderline(color:UIColor, withThickness thickness:CGFloat) {
            underLine.backgroundColor = color
            underLine.constraints.filter { ($0.identifier == "underlineHeight") }.first?.constant = thickness
        }
        
        switch style {
        case .none:
            setupUnderline(color: UIColor.clear, withThickness: 0)
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
        case .underline:
            if isActive { setupUnderline(color: activeBorderLineColor, withThickness: activeBorderLineThickness) }
            else { setupUnderline(color: borderLineColor, withThickness: borderLineThickness) }
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor
        case .box:
            setupUnderline(color: UIColor.clear, withThickness: 0)
            containerView.layer.borderWidth = isActive ? activeBorderLineThickness : borderLineThickness
            if isError {
                containerView.layer.borderColor = isActive ? activeBorderLineColor.cgColor : borderLineColor.cgColor
            } else {
                containerView.layer.borderColor = isActive ? activeBorderLineColor.cgColor : borderLineColor.cgColor
            }
        }
     }
    
    @IBAction fileprivate func refreshPinView(completionHandler: (()->())? = nil) {
        isLoading = true
        collectionView.reloadData()
    }
    
    fileprivate func showPinError(error: String) {
        didReceiveError?(NSError(domain: "SVPinView", code: 0, userInfo: [NSLocalizedDescriptionKey: error]))
        print("\n----------SVPinView Error----------")
        print(error)
        print("-----------------------------------")
    }
    
    // MARK: - Public methods -
    
    /// Returns the entered PIN; returns empty string if incomplete
    /// - Returns: The entered PIN.
    @objc
    public func getPin() -> String {
        
        guard !isLoading else { return "" }
        guard password.count == pinLength && password.joined().trimmingCharacters(in: CharacterSet(charactersIn: " ")).count == pinLength else {
            return ""
        }
        return password.joined()
    }
        
    /// Clears the entered PIN and refreshes the view
    /// - Parameter completionHandler: Called after the pin is cleared the view is re-rendered.
    @objc
    public func clearPin(completionHandler: (()->())? = nil) {
        
        guard !isLoading else { return }
        
        password.removeAll()
        refreshPinView(completionHandler: completionHandler)
    }
    
    /// Clears the entered PIN and refreshes the view.
    /// (internally calls the clearPin method; re-declared since the name is more intuitive)
    /// - Parameter completionHandler: Called after the pin is cleared the view is re-rendered.
    @objc
    public func refreshView(completionHandler: (()->())? = nil) {
        clearPin(completionHandler: completionHandler)
    }
    
    /// Pastes the PIN onto the PinView
    /// - Parameter pin: The pin which is to be entered onto the PinView.
    @objc
    public func pastePin(pin: String) {
        
        password = []
        for (index,char) in pin.enumerated() {

            guard index < pinLength else { return }

            // Get the first textField
            guard let cell = (collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? SVPinCell) else {
                showPinError(error: "ERR-103: Type Mismatch")
                return
            }
            
            let textField = cell.pinField
            let placeholderLabel = cell.placeholderLabel
            textField.text = String(char)
            placeholderLabel.isHidden = true

            //secure text after a bit
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(secureTextDelay), execute: {
                if textField.text != "" {
                    if self.shouldSecureText { textField.text = self.secureCharacter } else {}
                }
            })

            // store text
            password.append(String(char))
            validateAndSendCallback()
        }
    }
    
    @objc
    public func reloadStyles() {
        for i in 0..<pinLength {
            guard let cell = collectionView.cellForItem(at: IndexPath(item: i, section: 0)) as? SVPinCell else { continue }
            stylePinField(containerView: cell.containerView, underLine: cell.underlineView, isActive: cell.pinField.isFirstResponder)
        }
    }
}

// MARK: - CollectionView methods -
extension SVPinView : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pinLength
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        guard let pinCell = cell as? SVPinCell else { return cell }
        
        let textField = pinCell.pinField
        let containerView = pinCell.containerView
        let underLine = pinCell.underlineView
        let placeholderLabel = pinCell.placeholderLabel

        
        // Setting up textField
        if password.count > indexPath.row {
            textField.text = password[indexPath.row]
        } else {
            textField.text = ""
        }
        textField.tag = 101 + indexPath.row
        textField.isSecureTextEntry = false
        textField.textColor = self.textColor
        textField.tintColor = self.tintColor
        textField.font = self.font
        textField.deleteButtonAction = self.deleteButtonAction
        if #available(iOS 12.0, *), indexPath.row == 0, isContentTypeOneTimeCode {
            textField.textContentType = .oneTimeCode
        }
        textField.keyboardType = self.keyboardType
        textField.keyboardAppearance = self.keyboardAppearance
        textField.inputAccessoryView = self.pinInputAccessoryView
        
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        placeholderLabel.text = ""
        placeholderLabel.textColor = self.textColor.withAlphaComponent(0.5)
        
        stylePinField(containerView: containerView, underLine: underLine, isActive: false)
        
        // Make the Pin field the first responder
        if let firstResponderIndex = becomeFirstResponderAtIndex, firstResponderIndex == indexPath.item {
            textField.becomeFirstResponder()
        }
        
        // Finished loading pinView
        if indexPath.row == pinLength - 1 && isLoading {
            isLoading = false
            DispatchQueue.main.async {
                if !self.placeholder.isEmpty { self.setPlaceholder() }
            }
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
            let width = (collectionView.bounds.width - (interSpace * CGFloat(max(pinLength, 1) - 1)))/CGFloat(pinLength)
            return CGSize(width: width, height: collectionView.frame.height)
        }
        let width = (collectionView.bounds.width - (interSpace * CGFloat(max(pinLength, 1) - 1)))/CGFloat(pinLength)
        let roundedWidth = width.rounded(.down)
        let height = collectionView.frame.height
        return CGSize(width: roundedWidth, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return interSpace
    }
    
    public override func layoutSubviews() {
        flowLayout.invalidateLayout()
    }
}
// MARK: - TextField Methods -
extension SVPinView : UITextFieldDelegate
{
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        let passwordIndex = (textField.tag - 100) - 1
        guard let cell = collectionView.cellForItem(at: .init(item: passwordIndex, section: 0)) as? SVPinCell else { return }
        let text = textField.text ?? ""
        let placeholderLabel = cell.placeholderLabel
        placeholderLabel.isHidden = true
        
        if text.count == 0 {
            textField.isSecureTextEntry = false
            placeholderLabel.isHidden = false
        } else if deleteButtonAction == .moveToPreviousAndDelete {
            textField.text = ""
            if password.count > (passwordIndex) {
                password[passwordIndex] = ""
                textField.isSecureTextEntry = false
                placeholderLabel.isHidden = false
            }
        }
        
        let containerView = cell.containerView
        let underLine = cell.underlineView
        self.stylePinField(containerView: containerView, underLine: underLine, isActive: true)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        let passwordIndex = (textField.tag - 100) - 1
        guard let cell = collectionView.cellForItem(at: .init(item: passwordIndex, section: 0)) as? SVPinCell else { return }

        let containerView = cell.containerView
        let underLine = cell.underlineView
        self.stylePinField(containerView: containerView, underLine: underLine, isActive: false)
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string.count >= pinLength) && (string == UIPasteboard.general.string || isContentTypeOneTimeCode) {
            textField.resignFirstResponder()
            DispatchQueue.main.async { self.pastePin(pin: string) }
            return false
        } else if let cursorLocation = textField.position(from: textField.beginningOfDocument, offset: (range.location + string.count)),
            cursorLocation == textField.endOfDocument {
            // If the user moves the cursor to the beginning of the field, move it to the end before textEntry,
            // so the oldest digit is removed in textFieldDidChange: to ensure single character entry
            textField.selectedTextRange = textField.textRange(from: cursorLocation, to: textField.beginningOfDocument)
        }
        return true
    }
}
