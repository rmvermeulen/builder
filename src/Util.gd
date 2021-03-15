class_name Util

static func bind(emitter: Object, sig: String, receiver: Object, cb: String = ""):
	assert(emitter.has_signal(sig), "unknown signal '%s'" % sig)
	if cb.empty():
		cb = "_on_%s" % sig
	assert(receiver.has_method(cb), "unknown method '%s'" % cb)
	var error := emitter.connect(sig, receiver, cb)
	assert(error == OK, "connection failed, error: %d" % error)
