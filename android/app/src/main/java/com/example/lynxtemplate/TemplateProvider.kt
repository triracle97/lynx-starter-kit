package com.example.lynxtemplate

import android.content.Context
import com.lynx.tasm.provider.AbsTemplateProvider
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class TemplateProvider(private val ctx: Context) : AbsTemplateProvider() {
  private val io = Executors.newSingleThreadExecutor()

  override fun loadTemplate(url: String, callback: Callback) {
    io.execute {
      try {
        val bytes = if (url.startsWith("http://") || url.startsWith("https://")) {
          (URL(url).openConnection() as HttpURLConnection).run {
            connectTimeout = 5000
            readTimeout = 10000
            inputStream.use { it.readBytes() }
          }
        } else {
          val name = url.substringAfterLast('/').ifEmpty { "main.lynx.bundle" }
          ctx.assets.open(name).use { it.readBytes() }
        }
        callback.onSuccess(bytes)
      } catch (t: Throwable) {
        callback.onFailed(t.message ?: "load failed")
      }
    }
  }
}
