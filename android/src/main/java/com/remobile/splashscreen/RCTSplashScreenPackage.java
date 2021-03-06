package com.remobile.splashscreen;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import android.content.Intent;
import android.app.Activity;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;


public class RCTSplashScreenPackage implements ReactPackage {

    private RCTSplashScreen mModuleInstance;
    private String imageUrl;
    private Activity activity;

    public RCTSplashScreenPackage(Activity activity, String imageUrl) {
        super();
        this.imageUrl = imageUrl;
        this.activity = activity;
    }


    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        mModuleInstance = new RCTSplashScreen(reactContext, this.activity, this.imageUrl);
        return Arrays.<NativeModule>asList(
                mModuleInstance
        );
    }

    @Override
    public List<Class<? extends JavaScriptModule>> createJSModules() {
        return Collections.emptyList();
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        return Arrays.<ViewManager>asList();
    }
}
