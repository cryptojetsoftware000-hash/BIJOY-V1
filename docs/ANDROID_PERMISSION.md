# Android Permission

Flutter project generate করার পর এই permission AndroidManifest.xml এ থাকা দরকার:

File:

```text
flutter_app/android/app/src/main/AndroidManifest.xml
```

`<manifest>` tag এর ভিতরে add করো:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Example:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="BIJOY Chat Pro"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

Usually Flutter internet permission auto handle করে, কিন্তু LAN socket app এর জন্য এটা থাকা safe।
