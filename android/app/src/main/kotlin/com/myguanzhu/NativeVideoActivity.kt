package com.myguanzhu

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
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.VideoView

class NativeVideoActivity : Activity() {
    companion object {
        const val EXTRA_URL = "video_url"
        const val EXTRA_TITLE = "video_title"
        const val EXTRA_AUDIO_URL = "audio_url"
    }

    private lateinit var videoView: VideoView
    private lateinit var loading: LinearLayout
    private lateinit var errorText: TextView
    private var videoPlayer: MediaPlayer? = null
    private var audioPlayer: MediaPlayer? = null
    private var videoPrepared = false
    private var audioPrepared = false
    private var hasExternalAudio = false

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
                togglePlayback()
            }
        }
        loading = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(42, 34, 42, 36)
            setBackgroundColor(0xDD10101E.toInt())
            layoutParams = FrameLayout.LayoutParams(
                560,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
            addView(ProgressBar(this@NativeVideoActivity, null, android.R.attr.progressBarStyleHorizontal).apply {
                isIndeterminate = true
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    12
                )
            })
            addView(TextView(this@NativeVideoActivity).apply {
                text = "正在加载视频..."
                setTextColor(0xFFFFFFFF.toInt())
                textSize = 13f
                gravity = Gravity.CENTER
                typeface = android.graphics.Typeface.DEFAULT_BOLD
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = 22
                }
            })
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
        val audioUrl = intent.getStringExtra(EXTRA_AUDIO_URL)
        hasExternalAudio = !audioUrl.isNullOrBlank()
        if (url.isNullOrBlank()) {
            showError("Video url is empty")
            return
        }

        videoView.setVideoURI(Uri.parse(url))
        videoView.setOnPreparedListener { player: MediaPlayer ->
            videoPlayer = player
            videoPrepared = true
            player.isLooping = false
            if (hasExternalAudio) {
                player.setVolume(0f, 0f)
            } else {
                player.setVolume(1f, 1f)
            }
            fitVideoToScreen(player.videoWidth, player.videoHeight)
            startWhenReady()
        }
        videoView.setOnErrorListener { _, what, extra ->
            showError("Video playback failed: what=$what extra=$extra")
            true
        }
        if (hasExternalAudio) {
            prepareExternalAudio(audioUrl!!)
        }
        videoView.requestFocus()
    }

    override fun onPause() {
        super.onPause()
        if (::videoView.isInitialized && videoView.isPlaying) {
            videoView.pause()
        }
        audioPlayer?.pause()
    }

    override fun onDestroy() {
        if (::videoView.isInitialized) {
            videoView.stopPlayback()
        }
        audioPlayer?.release()
        audioPlayer = null
        super.onDestroy()
    }

    private fun prepareExternalAudio(audioUrl: String) {
        audioPrepared = false
        audioPlayer = MediaPlayer().apply {
            setDataSource(this@NativeVideoActivity, Uri.parse(audioUrl))
            setOnPreparedListener {
                audioPrepared = true
                startWhenReady()
            }
            setOnErrorListener { _, what, extra ->
                hasExternalAudio = false
                videoPlayer?.setVolume(1f, 1f)
                if (videoPrepared) {
                    loading.visibility = LinearLayout.GONE
                    videoView.start()
                } else {
                    showError("Audio playback failed: what=$what extra=$extra")
                }
                true
            }
            prepareAsync()
        }
    }

    private fun startWhenReady() {
        if (!videoPrepared) return
        if (hasExternalAudio && !audioPrepared) return
        loading.visibility = LinearLayout.GONE
        videoView.start()
        audioPlayer?.start()
    }

    private fun togglePlayback() {
        if (videoView.isPlaying) {
            videoView.pause()
            audioPlayer?.pause()
        } else {
            audioPlayer?.seekTo(videoView.currentPosition)
            videoView.start()
            audioPlayer?.start()
        }
    }

    private fun showError(message: String) {
        loading.visibility = LinearLayout.GONE
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
