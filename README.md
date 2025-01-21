# mediapipe_llminference_example
This Flutter example provides a minimal integration with custom LLM (Large Language Model) inference using platform channels. It enables developers to initialize models, generate synchronous or asynchronous responses, and dynamically process results, making it ideal for showcasing LLM functionality in cross-platform applications.


### Tested on Devices:

Samsung A31
Samsung A15 


### Considerations for project setup

In AndroidManifest.xml added  android:largeHeap="true" in application Tag.
In AndroidManifest.xml added <uses-native-library android:name="libOpenCL.so" android:required="false"/>

---------------------------------


### Project Overview 
**Widget Layer**

 1. Initialize Model Button     
     onPressed: calls           
     LlmService.initializeModel()
                                
 2. Generate Response Button    
     onPressed: calls           
    LlmService.generateResponse()


**Service Layer: LlmService**

 1. initializeModel()           |
     -> Calls MethodChannel.invokeMethod('initialize', {...}) 
                                |
 2. generateResponse()          
     -> Calls MethodChannel.invokeMethod('generateResponse', {...}) 



**Native Code: Kotlin**

 MethodChannel Handler (MainActivity.kt) 

 1. 'initialize'                        
    -> Executes Kotlin logic to load the model 
 2. 'generateResponse'                  
     -> Executes logic to generate a response 



### Code Snippets for Each Step

**1. Widget Layer**

```
Initialize Model Button:
ElevatedButton(
  onPressed: LlmService().initializeModel(),
  child: const Text('Initialize Model'),
);


Generate Response Button:
ElevatedButton(
  onPressed: LlmService().generateResponse(_promptController.text),
  child: const Text('Sync Response'),
);
```


**2. Service Layer (LlmService)**

```
static const MethodChannel _channel =
      MethodChannel('com.example.mediapipe_llminference_example/inference');
Future<String> initializeModel() async {
  try {
    final result = await _channel.invokeMethod('initialize', {
      'modelPath': '/data/local/tmp/llm/model.bin',
      'maxTokens': 50,
      'temperature': 0.7,
      'randomSeed': 42,
      'topK': 40,
    });
    return 'Initialization result: $result';
  } catch (e) {
    return 'Error initializing model: $e';
  }
}


Future<String> generateResponse(String prompt) async {
  try {
    final result = await _channel.invokeMethod('generateResponse', {
      'prompt': prompt,
    });
    return result ?? 'No response received';
  } catch (e) {
    return 'Error generating response: $e';
  }
}
```



**3. Native Code (Kotlin)**


```
class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.mediapipe_llminference_example/inference"
    private var llmInference: LlmInference? = null
    private val partialResultsFlow = MutableSharedFlow<Pair<String, Boolean>>(
        extraBufferCapacity = 1,
        onBufferOverflow = BufferOverflow.DROP_OLDEST
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val modelPath = call.argument<String>("modelPath") ?: ""
                    val maxTokens = call.argument<Int>("maxTokens") ?: 50
                    val temperature: Float = (call.argument<Double>("temperature")?.toFloat() ?: 0.7f)
                    val randomSeed = call.argument<Int>("randomSeed") ?: 42
                    val topK = call.argument<Int>("topK") ?: 40

                    if (!File(modelPath).exists()) {
                        result.error("INIT_ERROR", "Model not found at path: $modelPath", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val options = LlmInference.LlmInferenceOptions.builder()
                            .setModelPath(modelPath)
                            .setMaxTokens(maxTokens)
                            .setTemperature(temperature)
                            .setRandomSeed(randomSeed)
                            .setTopK(topK)
                            .setResultListener { partialResult, done ->
                                partialResultsFlow.tryEmit(partialResult to done)
                            }
                            .build()

                        llmInference = LlmInference.createFromOptions(this, options)
                        result.success("Model initialized successfully")
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", "Failed to initialize: ${e.message}", null)
                    }
                }
                "generateResponse" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    try {
                        val response = llmInference?.generateResponse(prompt)
                        if (response != null) {
                            result.success(response)
                        } else {
                            result.error("GEN_ERROR", "Failed to generate response", null)
                        }
                    } catch (e: Exception) {
                        result.error("GEN_ERROR", "Error generating response: ${e.message}", null)
                    }
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Listen for partial results if necessary
        CoroutineScope(Dispatchers.Main).launch {
            partialResultsFlow.collectLatest { (partialResult, done) ->
                // Optional: Use EventChannel or logs to send partial results back to Flutter.
                println("Partial result: $partialResult, Done: $done")
            }
        }
    }
}


```




