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

extension NSTextField {
    
    convenience init(stringLabel: String) {
        self.init(frame: CGRect(x: 0, y: 0, width: 200, height: 17))
        stringValue = stringLabel
        bezeled = false
        drawsBackground = false
        editable = false
        selectable = false
    }
}

extension GTTag : NSCopying {

    public func copyWithZone(zone: NSZone) -> AnyObject {
        return GTTag(obj: self.git_tag(), inRepository: self.repository)!
    }
}

extension GTTag {
    
    @objc var isCurrentTag: Bool {
        if let tagSHA = self.target?.SHA {
            
            if let repoSHA = try? self.repository.headReference().OID.SHA {
                return tagSHA == repoSHA
            }
        }
        return false
    }
    
    @objc var isCurrentTagBullet: String {
        return self.isCurrentTag ? "•" : ""
    }
}

class ViewController: NSViewController {
    
    var repositoryURL: NSURL? { return self.representedObject as? NSURL }

    @IBOutlet weak var tableView: NSTableView!
    @objc var tags: [GTTag] = []
    
    var repo: GTRepository?
    var timer: NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.representedObject = NSURL(fileURLWithPath: "/Users/aufflick/src/CocoaHeads/MoyaTalk/Yum")

        self.tableView.target = self
        self.tableView.doubleAction = #selector(self.doubleAction(_:))

        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(self.timerFire(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func doubleAction(sender: NSTableView) {
        
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
    
    @objc func timerFire(timer: NSTimer) {
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
                
                do {
                    // don't quite understand swift kvo yet
                    self.willChangeValueForKey("tags")
                    tags = try repo!.allTags()
                    self.didChangeValueForKey("tags")
                } catch(let error) {
                    print("error getting tags: \(error)")
                }
            }
        }
    }


}

