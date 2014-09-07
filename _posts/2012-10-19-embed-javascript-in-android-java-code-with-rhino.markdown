---
layout: post
title: "Embed JavaScript in Android Java Code with Rhino"
date:   2012-10-19 02:41:08
---

In a recent Android project, I want to move some dynamic or unstable code from client App to server side, which will provide some RESTful APIs to Android Apps. However, this mechanism will increase the server burden highly, and if these code used other third party services, the requests may be too limited.

So I have been considering a mechanism to guarantee these dynamic logic stable without updating client App frequently, but the Apps could also do their jobs by themselves. After investigating several open source projects and proposals, I choosed [Rhino](https://developer.mozilla.org/en-US/docs/Rhino) to achieve my goal.


Prepare the server
------------------

I use Rails as my server framework, and create a RESTful script resource, so I can access a script content from `/scripts/1.json`, which will return some code you can change at any time. To demonstrate it:

```javascript
function hello(java) {
	if (typeof log != 'undefined') {
    	log("JavaScript say hello to " + java);

        log("Also, I can access Java object: " + javaContext);
    }

    return { foo: "bar in JavaScript" };
}
```

If you're familliar with JavaScript, the code above is just simple. However, you may wonder where is the `log` and `javaContext` from? Well, mystery will disappear in next section.


Use Rhino
---------

Everything begins with you get it. [Download Rhino](https://developer.mozilla.org/en-US/docs/Rhino/Download_Rhino) then unzip it to get the `js.jar` file, we only need that file. As you can see, Rhino is only 1.0 MB, which is small enough to be embedded in an Android App.

In your favorite terminal, type below code to start Rhino console:

```bash
java -jar js.jar
```

It just works, you can type most JavaScript functions in the Rhino console to test them before coding.

As we wanna use it in our Android project, we need to put the js.jar in project's libs folder. Then we can use the simple API of Rhino.

Now I will put some simple code here, everything will be clear if you follow the code comments.

```java
// class ScriptAPI

// These lines set the log method in the JavaScript
// Any Java classes or methods can be accessed with **Packages** prefix
private static final String RHINO_LOG = "var log = Packages.io.vec.ScriptAPI.log;";
public static void log(String msg) {
	android.util.Log.i("RHINO_LOG", msg);
}

public void runScript() {
	// Get the JavaScript in previous section
	String source = getScriptFromServer();
    String functionName = "hello";
    Object[] functionParams = new Object[] { "Android" };

    // Every Rhino VM begins with the enter()
    // This Context is not Android's Context
	Context rhino = Context.enter();

    // Turn off optimization to make Rhino Android compatible
	rhino.setOptimizationLevel(-1);
	try {
		Scriptable scope = rhino.initStandardObjects();

    // This line set the javaContext variable in JavaScript
    ScriptableObject.putProperty(scope, "javaContext", Context.javaToJS(androidContextObject, scope));

		// Note the forth argument is 1, which means the JavaScript source has
    // been compressed to only one line using something like YUI
		rhino.evaluateString(scope, RHINO_LOG + source, "ScriptAPI", 1, null);

		// We get the hello function defined in JavaScript
		Function function = (Function) scope.get(functionName, scope);

    // Call the hello function with params
		NativeObject result = (NativeObject) function.call(rhino, scope, scope, functionParams));
    // After the hello function is invoked, you will see logcat output

    // Finally we want to print the result of hello function
    String foo = (String) Context.jsToJava(result.get("foo", result), String.class);
    log(foo);
	} finally {
    // We must exit the Rhino VM
		Context.exit();
	}
}
```

So, it's easy, and the Rhino documentation is also easy to understand.


Rhino and Proguard
------------------

When obscure code with Proguard, the following two lines are needed to bypass the warnings and notes for Rhino:

```java
-dontwarn org.mozilla.javascript.**
-dontwarn org.mozilla.classfile.**
```

Even no warings about Rhino, we still can't make Proguard happy, it will throw me an exception:

```java
java.lang.IllegalArgumentException: Can't find any super classes of [org/mozilla/javascript/tools/debugger/FileWindow] (not even immediate super class [javax/swing/JInternalFrame])
```

I don't know how to make Proguard ignore the Java classes which produce the error. So I just delete the `org.mozilla.javascript.tools` package from the js.jar file, because I don't need the classes in Rhino tools, which are used as a convenient interactive shell.


Troubleshooting
---------------

If you find any method not exist in Rhino, such as `XMLHttpRequest`, you can define it with Java and pass it to JavaScript just like we do with the `RHINO_LOG`.

So let's define the `readUrl` method, which exists in Rhino console, but not a core API.

```java
private static final String RHINO_READURL = "var readUrl = Packages.io.vec.ScriptAPI.readUrl;";
public static String readUrl(String url) {
	// Read the HTML text with HttpClient
}
```

That's it, unless you use Proguard. When the code obscured with Proguard, even you skipped the ScriptAPI class and its members, Rhino still complains it can't find class blah, blah. When the `Packages` magic fails, I choosed Java reflection.

```java
ScriptableObject.putProperty(scope, "javaLoader", Context.javaToJS(ScriptAPI.class.getClassLoader(), scope));

private static final String RHINO_READURL = "var ScriptAPI = " +
	"java.lang.Class.forName(\"" + ScriptAPI.class.getName() + "\", true, javaLoader);" +
	"var methodRead = ScriptAPI.getMethod(\"readUrl\", [java.lang.String]);" +
	"var readUrl = function(url) {return methodRead.invoke(null, url);};";
```

Then just prepend the `RHINO_READURL` String before your other JS code.


Security
--------

There're several SO questions on this topic, such as [How can you run Javascript using Rhino for Java in a sandbox?
](http://stackoverflow.com/questions/93911/how-can-you-run-javascript-using-rhino-for-java-in-a-sandbox)
