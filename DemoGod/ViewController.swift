//
//  ViewController.swift
//  DemoGod
//
//  Created by Mark Aufflick on 15/09/2016.
//  Copyright © 2016 The High Technology Bureau. All rights reserved.
//

import Cocoa
import ObjectiveGit

class TitledView: NSView {
    
    var title: String = "" {
        didSet {
            self.window?.title = title
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        self.window?.title = title
    }
}

extension GTTag : NSCopying {

    public func copyWithZone(zone: NSZone) -> AnyObject {
        return GTTag(obj: self.git_tag(), inRepository: self.repository)!
    }
}

extension GTTag {
    
    var isCurrentTag: Bool {
        if let tagSHA = self.target?.SHA {
            
            if let repoSHA = try? self.repository.headReference().OID.SHA {
                return tagSHA == repoSHA
            }
        }
        return false
    }
    
    var isCurrentTagBullet: String {
        return self.isCurrentTag ? "•" : ""
    }
}

extension ViewController: NSOpenSavePanelDelegate {
    
    func panel(sender: AnyObject, validateURL url: NSURL) throws {
        
        if !self.validateURLForOpening(url) {
        
        let error = NSError(domain: "argh", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "That directory is not a git repository",
            NSLocalizedFailureReasonErrorKey: "You must select a directory that has a valid .git dir in it"
            ])
            
            throw error
        }
    }
}

class ViewController: NSViewController {
    
    var repositoryURL: NSURL? { return self.representedObject as? NSURL }

    @IBOutlet weak var tableView: NSTableView!
    @objc var tags: [GTTag] = [] {
        willSet {
            self.willChangeValueForKey("tags")
        }
        didSet {
            self.didChangeValueForKey("tags")
        }
    }
    
    var repo: GTRepository?
    var fastTimer: NSTimer?
    var slowTimer: NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.target = self
        self.tableView.doubleAction = #selector(self.doubleAction(_:))

        fastTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(self.fastTimerFire(_:)), userInfo: nil, repeats: true)
        slowTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(self.slowTimerFire(_:)), userInfo: nil, repeats: true)
    }
    
    var openPanel: NSOpenPanel?
    
    func validateURLForOpening(url: NSURL?) -> Bool {
        
        if let url = url {
            
            let gitPath = url.URLByAppendingPathComponent(".git").path!
            
            var isDir: ObjCBool = false
            if NSFileManager().fileExistsAtPath(gitPath, isDirectory: &isDir) && isDir {
                return true
            }
        }

        return false
    }
    
    @objc func openPath(path: String) {
        
        let url = NSURL(fileURLWithPath: path)

        if self.validateURLForOpening(url) {
            self.representedObject = url
        }
    }
    
    func openDocument(sender: AnyObject?) {
        
        openPanel = NSOpenPanel()
        
        if let panel = openPanel {
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.message = "Choose your git repo"
            panel.prompt = "I am a Demo God"
            panel.delegate = self
            panel.beginSheetModalForWindow(view.window!, completionHandler: { returnCode in
                
                if returnCode == NSFileHandlingPanelOKButton {
                    
                    if self.validateURLForOpening(panel.directoryURL) {
                    
                        NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(panel.directoryURL!)
                        self.representedObject = panel.directoryURL!
                    }
                }
            })
        }
    }
    
    func doubleAction(sender: NSTableView) {
        
        let tag = tags[sender.clickedRow]
        
        
        "DemoGod".withCString { name in
            "demogod@theinternet".withCString { email in
                
                var sig = git_signature(
                    name: unsafeBitCast(name, UnsafeMutablePointer<Int8>.self),
                    email: unsafeBitCast(email, UnsafeMutablePointer<Int8>.self),
                    when: git_time(time: Int64(time(nil)), offset: 0))
                
                let out_oid = UnsafeMutablePointer<git_oid>(malloc(sizeof(git_oid)))

                "Stashed by DemoGod".withCString { message in
                    
                    git_stash_save(out_oid, repo!.git_repository(), &sig, message, GIT_STASH_INCLUDE_UNTRACKED.rawValue)
                    
                    free(out_oid)
                    
                }
            }
        }
        
        if let commit = tag.target as? GTCommit {
        
            do {
                try repo?.checkoutCommit(commit, strategy: .Force, progressBlock: nil)
            } catch(let error) {
                print("error doing checkout: \(error)")
            }
            
        }
        
    }
    
    func updateTags() {
        
        if let repo = repo {
            do {
                tags = try repo.allTags()
            } catch(let error) {
                print("error getting tags: \(error)")
            }
        }
    }
    
    func slowTimerFire(timer: NSTimer) {
        self.updateTags()
    }
    
    func fastTimerFire(timer: NSTimer) {
        
        for tag in tags {
            tag.willChangeValueForKey("isCurrentTagBullet")
            tag.didChangeValueForKey("isCurrentTagBullet")
        }
    }

    override var representedObject: AnyObject? {
        didSet {
            
            if let repositoryURL = repositoryURL {
                
                do {
                    repo = try GTRepository(URL: repositoryURL)
                    
                } catch(let error) {
                    print("error: \(error)")
                    abort()
                }
                
                if let view = self.view as? TitledView {
                    view.title = repositoryURL.lastPathComponent!
                }
                
                self.updateTags()
            }
        }
    }


}

