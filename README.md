# Documentation
This module can be used to detect when an instance is destroyed at any point after it is used on the object.  
It will detect when the object is destroyed from the game hierarchy and when it is destroyed from nil.  
The call returns a pseudo-signal which can be used to check if the function is connected and can be used to disconnect the on-destroy-function without causing it to fire.
		
		
* pseudoSignal module(Instance instance, function func)  
Attach the function 'func' to be called when the Instance 'instance' is destroyed


* pseudoSignal
  * boolean         .connected  
If the function provided is still connected then this is true. When the object is destroyed this is set to false before the function is called.  
This can only be false if the object is destroyed or if this is manually disconnected.

  * void            :disconnect()  
Manually disconnects the connected function before the object is destroyed.

  * RBXScriptSignal .connection  
This is the actual connection to the instance's AncestryChanged event. This should not be messed with.


# Changes pre-git-repo
* Edit 5:  
Clarify comments on coroutine.yield because behavior has changed from [end of current execution cycle] to [beginning of next execution cycle]
* Version 4:  
Fixed garbage collection detection.
* Edit 3:  
Clarified/fixed some terminology. (comments only)
* Version 2:  
Made it not prevent garbage collection by using ObjectValues
* Version 1:  
Initial

See original Gist for diffs: https://gist.github.com/Corecii/2c86fb338802a618e3ff376d61409b1b
