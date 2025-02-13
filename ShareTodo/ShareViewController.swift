//
//  ShareViewController.swift
//  ShareTodo
//
//  Created by Swastik Patil on 2/10/25.
//

import UIKit
import Social
import SharedModels
import WidgetKit
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: UIViewController {
    private var selectedCategory: SharedModels.Category = .personal
    
    private lazy var navigationBar: UINavigationBar = {
        let nav = UINavigationBar()
        nav.translatesAutoresizingMaskIntoConstraints = false
        let item = UINavigationItem(title: "Add Task")
        item.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        item.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        nav.items = [item]
        return nav
    }()
    
    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 8
        tf.placeholder = "Task Title"
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        tf.leftViewMode = .always
        return tf
    }()
    
    private lazy var notesTextView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        return tv
    }()
    
    private lazy var linkPreviewView: LinkPreviewView = {
        let preview = LinkPreviewView()
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.isHidden = true
        return preview
    }()
    
    private lazy var categoryPicker: UISegmentedControl = {
        let segmented = UISegmentedControl(items: ["Personal", "Work", "College"])
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(categoryChanged(_:)), for: .valueChanged)
        return segmented
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSharedContent()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(navigationBar)
        view.addSubview(titleTextField)
        view.addSubview(notesTextView)
        view.addSubview(linkPreviewView)
        view.addSubview(categoryPicker)
        
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleTextField.topAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            notesTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            notesTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notesTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notesTextView.heightAnchor.constraint(equalToConstant: 120),
            
            linkPreviewView.topAnchor.constraint(equalTo: notesTextView.bottomAnchor, constant: 16),
            linkPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            linkPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            linkPreviewView.heightAnchor.constraint(equalToConstant: 120),
            
            categoryPicker.topAnchor.constraint(equalTo: linkPreviewView.bottomAnchor, constant: 16),
            categoryPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func loadSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else { return }
        
        for attachment in extensionItem.attachments ?? [] {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                    guard let self = self, let url = data as? URL, error == nil else { return }
                    DispatchQueue.main.async {
                        self.notesTextView.text = url.absoluteString
                        self.linkPreviewView.isHidden = false
                        self.linkPreviewView.loadPreview(for: url.absoluteString)
                    }
                }
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (data, error) in
                    guard let self = self, let text = data as? String, error == nil else { return }
                    DispatchQueue.main.async {
                        if let url = self.extractURL(from: text) {
                            self.notesTextView.text = text
                            self.linkPreviewView.isHidden = false
                            self.linkPreviewView.loadPreview(for: url.absoluteString)
                        } else {
                            self.notesTextView.text = text
                            self.linkPreviewView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    private func extractURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches?.first?.url
    }
    
    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            selectedCategory = .personal
        case 1:
            selectedCategory = .work
        case 2:
            selectedCategory = .college
        default:
            selectedCategory = .personal
        }
    }
    
    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let newTask = TodoItem(
            id: UUID(),
            title: title,
            isCompleted: false,
            dueDate: nil,
            dueTime: nil,
            category: selectedCategory,
            notes: notesTextView.text,
            priority: .medium,
            images: [],
            notificationId: nil
        )
        
        // Save to shared UserDefaults
        if let userDefaults = UserDefaults(suiteName: "group.com.swastik.Something-New") {
            var todos: [TodoItem] = []
            if let data = userDefaults.data(forKey: "todos"),
               let existingTodos = try? JSONDecoder().decode([TodoItem].self, from: data) {
                todos = existingTodos
            }
            
            todos.append(newTask)
            
            if let encoded = try? JSONEncoder().encode(todos) {
                userDefaults.set(encoded, forKey: "todos")
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func categoryColor(for category: SharedModels.Category) -> Color {
        switch category {
        case .personal: return .purple
        case .work: return .green
        case .college: return .orange
        }
    }
}
