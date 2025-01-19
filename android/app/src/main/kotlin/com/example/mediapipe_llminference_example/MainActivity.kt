package com.example.mediapipe_llminference_example

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import java.io.File
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

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
                "generateResponseAsync" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            llmInference?.generateResponseAsync(prompt)
                        }
                        result.success("Async response generation started")
                    } catch (e: Exception) {
                        result.error("ASYNC_GEN_ERROR", "Error starting async generation: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
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
