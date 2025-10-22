//  ButtonBarViewCell.swift
//  TKPagerTabStrip
//

import UIKit
import Foundation

public class ButtonBarViewCell: UICollectionViewCell {
    open override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            super.isSelected = newValue
            if (newValue) {
                accessibilityTraits.insert(.selected)
            } else {
                accessibilityTraits.remove(.selected)
            }
        }
    }
    // MARK: - Subviews
    public let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        return label
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Set your image here if needed, e.g. imageView.image = UIImage(named: "yourImage")
        return imageView
    }()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup
    private func setupViews() {
        isAccessibilityElement = true
        accessibilityTraits.insert([.button, .header])

        // Background color: #07BA9B
        contentView.backgroundColor = UIColor(red: 0.027, green: 0.725, blue: 0.608, alpha: 1)

        contentView.addSubview(imageView)
        contentView.addSubview(label)

        // ImageView constraints (35x35, centered)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 35),
            imageView.heightAnchor.constraint(equalToConstant: 35),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        // Label constraints (centered)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
