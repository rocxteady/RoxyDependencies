//
//  SVPinCell.swift
//  SVPinView
//
//  Created on 12.12.2024.
//

import UIKit

class SVPinCell: UICollectionViewCell {
    // MARK: - Subviews
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.tag = 51
        return view
    }()

    let pinField: SVPinField = {
        let field = SVPinField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 18)
        field.tag = 100
        return field
    }()

    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18)
        label.tag = 400
        return label
    }()

    let underlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.tag = 50
        return view
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
        contentView.addSubview(containerView)
        containerView.addSubview(pinField)
        containerView.addSubview(placeholderLabel)
        containerView.addSubview(underlineView)

        // ContainerView constraints (fill cell)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // PinField constraints (top, left, right, height 47)
        NSLayoutConstraint.activate([
            pinField.topAnchor.constraint(equalTo: containerView.topAnchor),
            pinField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pinField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pinField.bottomAnchor.constraint(equalTo: underlineView.topAnchor)
        ])

        // PlaceholderLabel constraints (fill container)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            placeholderLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // UnderlineView constraints (height 3, left, right, bottom, top to pinField's bottom)
        NSLayoutConstraint.activate([
            underlineView.topAnchor.constraint(equalTo: pinField.bottomAnchor),
            underlineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            underlineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            underlineView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 3)
        ])
    }
}
