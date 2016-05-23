package com.remobile.splashscreen;

import java.lang.ref.SoftReference;

import android.content.Context;
import android.graphics.Bitmap;
import android.os.Handler;
import android.util.AttributeSet;
import android.widget.ImageView;

import java.io.File;
import java.io.FileOutputStream;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

public final class UrlImageView extends ImageView {
    private final Context context;

    private Request request;
    private String url;
    private boolean isLoading = false;
    private final Handler handler = new Handler();


    private final Runnable threadRunnable = new Runnable() {
        public void run() {
            handler.post(imageLoadRunnable);
        }
    };

    private final Runnable imageLoadRunnable = new Runnable() {
        public void run() {
            setImageLocalCache();
        }
    };

    class Request {
        private final String url;
        private final File cacheDir;
        private final Runnable runnable;
        private Status status = Status.WAIT;

        public enum Status {
            WAIT, LOADING, LOADED
        }

        public Request(String url, File cacheDir) {
            this.url = url;
            this.cacheDir = cacheDir;
            this.runnable = getDefaultRunnable();
        }


        public Request(String url, File cacheDir, Runnable runnable) {
            this.url = url;
            this.cacheDir = cacheDir;
            this.runnable = runnable;
        }


        public synchronized void setStatus(Status status) {
            this.status = status;
        }


        public synchronized Status getStatus() {
            return (status);
        }


        public String getUrl() {
            return (url);
        }


        public File getCacheDir() {
            return (cacheDir);
        }


        public Runnable getRunnable() {
            return ((runnable != null) ? runnable : getDefaultRunnable());
        }


        private Runnable getDefaultRunnable() {
            return (new Runnable() {
                public void run() {}
            });
        }
    }


    private boolean setImageLocalCache() {
        Bitmap image = getImage(context.getCacheDir(), url);
        if (image != null && image.get() != null) {
            setImageBitmap(image.get());
            isLoading = false;
            return (true);
        }
        return (false);
    }


    public UrlImageView(Context context) {
        super(context);
        this.context = context;
    }


    public void saveBitmap(File cacheDir, String fileName, Bitmap bitmap) {
        File localFile = new File(cacheDir, fileName);
        FileOutputStream fos = null;
        try {
            fos = new FileOutputStream(localFile);
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, fos);
        } catch (Exception e) {
            e.printStackTrace();
        } catch (OutOfMemoryError e) {
            e.printStackTrace();
        } finally {
            if (fos != null) {
                try {
                    fos.close();
                } catch (IOException e1) {
                    Log.w("save", "finally");
                }
            }
        }
    }


    public Bitmap getImage(File cacheDir, String fileName) {
        File localFile = new File(cacheDir, fileName);
        Bitmap bitmap = null;
        try {
            bitmap = new BitmapFactory.decodeFile(localFile.getPath());
        } catch (Exception e) {
            e.printStackTrace();
        } catch (OutOfMemoryError e) {
            e.printStackTrace();
        }
        return (bitmap);
    }


    public void setImageUrl(String url, int placeholderImageId) {
        Bitmap image = this.getImage(context.getCacheDir(), 'splash');
        if (image != null) {
            setImageBitmap(image);
        } else if (placeholderImageId != 0) {
            this.setImageResource(placeholderImageId);
        } else {
            this.url = url;
            isLoading = true;
            request = new Request(url, context.getCacheDir(), threadRunnable);
            if (setImageLocalCache()) {
                return;
            }
            new Thread(new Runnable() {
                public void run() {
                    doRequest(request);
                }
            }).start();
        }
    }


    private void doRequest(Request request) {
        request.setStatus(Request.Status.LOADING);
        try {
            image = getBitmapFromURL(request.getUrl());
            saveBitmap(request.getCacheDir(), 'splash', image.get());
        } catch (Exception e) {
            e.printStackTrace();
        }
        request.setStatus(Request.Status.LOADED);
        request.getRunnable().run();
    }


    private Bitmap getBitmapFromURL(String strUrl) throws IOException {
        HttpURLConnection con = null;
        InputStream in = null;

        try {
            URL url = new URL(strUrl);
            con = (HttpURLConnection) url.openConnection();
            con.setUseCaches(true);
            con.setRequestMethod("GET");
            con.setReadTimeout(500000);
            con.setConnectTimeout(50000);
            con.connect(); in = con.getInputStream();
            return (BitmapFactory.decodeStream( in ));
        } finally {
            try {
                if (con != null)
                    con.disconnect();
                if ( in != null)
                    in .close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }


    public Boolean isLoading() {
        return (isLoading);
    }
}
