import UIKit
import SodiumSwift
import SwiftCommon

/**
 ## Sodium TextField
 
 - Author: Andrew Bradnan
 - Date: 5/20/16
 - Copyright: © 2016 Whirlygig Ventures. All rights reserved.
 */
public class NATextField : UITextField {
    var refs: MemReferences?
    public var txt = CellSink<String>("") {
        didSet{
            self.userChanges = txt.stream()
        }
    }
    weak var userChanges: Stream<String>!
    private var l: Listener?
    
    public convenience init(s: Stream<String>, text: String, refs: MemReferences? = nil) {
        self.init(frame: CGRectZero, text: text, refs: refs)
    }
    
    public convenience init(text: String, refs: MemReferences? = nil) {
        self.init(frame: CGRectZero, text: text, refs: refs)
    }
    
    init(frame: CGRect, text: String, refs: MemReferences? = nil) {
        self.txt = CellSink<String>(text, refs: refs)
        self.refs = refs
        if let r = self.refs { r.addRef() }
        super.init(frame: frame)
        
        self.l = self.listen()
        self.text = text
        
        // Add a "textFieldDidChange" notification method to the text field control.
        self.addTarget(self, action: #selector(NATextField.textFieldDidChange), forControlEvents:UIControlEvents.EditingChanged)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.txt = CellSink<String>("", refs: self.refs)
        self.userChanges = txt.stream() // didSet doesn't work in init()
        self.l = self.listen()

        // Add a "textFieldDidChange" notification method to the text field control.
        self.addTarget(self, action: #selector(NATextField.textFieldDidChange), forControlEvents:UIControlEvents.EditingChanged)
    }

    deinit {
        if let r = self.refs { r.release() }
        print("NATextField deinit (should see Cell and Stream deinig)")
    }
    
    private var hiddenListener: Listener?
    public var hiddenState = Cell<Bool>(value: false) {
        didSet {
            self.hiddenListener = Operational.updates(hiddenState).listen { hidden in
                gui { self.hidden = hidden }
            }
        }
    }

    private func listen() -> Listener? {
        return self.userChanges.listen(self.refs) { [weak self] text in self!.text = text }
    }
    
    @objc private func textFieldDidChange(sender: UITextField) {
        self.txt.send(sender.text!)
    }
}
