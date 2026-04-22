package com.example.lynxtemplate

import android.app.Application
import com.lynx.tasm.LynxEnv
import com.lynx.service.http.LynxHttpService
import com.lynx.service.image.LynxImageService
import com.lynx.service.log.LynxLogService
import com.lynx.tasm.service.LynxServiceCenter

class LynxApp : Application() {
  override fun onCreate() {
    super.onCreate()
    LynxEnv.inst().init(this, null, null, null)
    LynxServiceCenter.inst().registerService(LynxImageService.getInstance())
    LynxServiceCenter.inst().registerService(LynxLogService.getInstance())
    LynxServiceCenter.inst().registerService(LynxHttpService.getInstance())
  }
}
