package com.onlydu

import android.app.Activity
import android.graphics.Color
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.VideoView

class NativeVideoActivity : Activity() {
    companion object {
        const val EXTRA_URL = "video_url"
        const val EXTRA_TITLE = "video_title"
    }

    private lateinit var videoView: VideoView
    private lateinit var loading: ProgressBar
    private lateinit var errorText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        super.onCreate(savedInstanceState)
        window.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT
        )
        window.setDimAmount(0.58f)

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener { finish() }
        }
        val panel = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
                Gravity.CENTER
            )
        }
        videoView = VideoView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener {
                if (isPlaying) {
                    pause()
                } else {
                    start()
                }
            }
        }
        loading = ProgressBar(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
        }
        errorText = TextView(this).apply {
            setTextColor(0xFFFFFFFF.toInt())
            textSize = 15f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ).apply {
                leftMargin = 32
                rightMargin = 32
            }
            visibility = TextView.GONE
        }

        panel.addView(videoView)
        panel.addView(loading)
        panel.addView(errorText)
        root.addView(panel)
        setContentView(root)

        val url = intent.getStringExtra(EXTRA_URL)
        if (url.isNullOrBlank()) {
            showError("Video url is empty")
            return
        }

        videoView.setVideoURI(Uri.parse(url))
        videoView.setOnPreparedListener { player: MediaPlayer ->
            loading.visibility = ProgressBar.GONE
            player.isLooping = false
            fitVideoToScreen(player.videoWidth, player.videoHeight)
            videoView.start()
        }
        videoView.setOnErrorListener { _, what, extra ->
            showError("Video playback failed: what=$what extra=$extra")
            true
        }
        videoView.requestFocus()
    }

    override fun onPause() {
        super.onPause()
        if (::videoView.isInitialized && videoView.isPlaying) {
            videoView.pause()
        }
    }

    override fun onDestroy() {
        if (::videoView.isInitialized) {
            videoView.stopPlayback()
        }
        super.onDestroy()
    }

    private fun showError(message: String) {
        loading.visibility = ProgressBar.GONE
        errorText.text = message
        errorText.visibility = TextView.VISIBLE
    }

    private fun fitVideoToScreen(videoWidth: Int, videoHeight: Int) {
        if (videoWidth <= 0 || videoHeight <= 0) return

        val screenWidth = resources.displayMetrics.widthPixels
        val maxHeight = (resources.displayMetrics.heightPixels * 0.58f).toInt()
        val videoAspect = videoWidth.toFloat() / videoHeight.toFloat()

        var targetWidth = screenWidth
        var targetHeight = (targetWidth / videoAspect).toInt()
        if (targetHeight > maxHeight) {
            targetHeight = maxHeight
            targetWidth = (targetHeight * videoAspect).toInt()
        }

        videoView.layoutParams = FrameLayout.LayoutParams(
            targetWidth,
            targetHeight,
            Gravity.CENTER
        )
    }
}
