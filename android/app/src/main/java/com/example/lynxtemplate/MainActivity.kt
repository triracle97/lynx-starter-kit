package com.example.lynxtemplate

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.lynx.tasm.LynxViewBuilder

class MainActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    val url = if (BuildConfig.DEBUG) {
      // Physical device: replace 10.0.2.2 with LAN IP printed by `pnpm dev:ip`
      "http://10.0.2.2:3000/main.lynx.bundle"
    } else {
      "embedded://main.lynx.bundle"
    }

    val lynx = LynxViewBuilder()
      .setTemplateProvider(TemplateProvider(this))
      .build(this)

    findViewById<android.widget.FrameLayout>(R.id.lynx_container).addView(lynx)
    lynx.renderTemplateUrl(url, "")
  }
}
