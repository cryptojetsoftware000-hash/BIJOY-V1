package com.bijoy.notepad;

import android.app.Activity;
import android.os.Bundle;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    private static final String PREFS = "bijoy_notepad";
    private static final String KEY_NOTE = "note";
    private EditText editor;
    private SharedPreferences prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(14), dp(14), dp(14), dp(14));
        root.setBackgroundColor(0xFFF7F9FC);

        TextView title = new TextView(this);
        title.setText("BIJOY Notepad");
        title.setTextSize(22);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setTextColor(0xFF0D47A1);
        title.setPadding(0, 0, 0, dp(10));
        root.addView(title, new LinearLayout.LayoutParams(-1, -2));

        editor = new EditText(this);
        editor.setText(prefs.getString(KEY_NOTE, ""));
        editor.setTextSize(18);
        editor.setGravity(Gravity.TOP | Gravity.START);
        editor.setHint("Write your notes here...");
        editor.setMinLines(12);
        editor.setBackgroundColor(0xFFFFFFFF);
        editor.setPadding(dp(12), dp(12), dp(12), dp(12));
        root.addView(editor, new LinearLayout.LayoutParams(-1, 0, 1));

        LinearLayout buttons = new LinearLayout(this);
        buttons.setOrientation(LinearLayout.HORIZONTAL);
        buttons.setPadding(0, dp(10), 0, 0);

        buttons.addView(btn("Save", new View.OnClickListener() {
            @Override public void onClick(View v) { saveNote(true); }
        }), new LinearLayout.LayoutParams(0, dp(48), 1));

        buttons.addView(btn("Copy", new View.OnClickListener() {
            @Override public void onClick(View v) { copyNote(); }
        }), new LinearLayout.LayoutParams(0, dp(48), 1));

        buttons.addView(btn("Share", new View.OnClickListener() {
            @Override public void onClick(View v) { shareNote(); }
        }), new LinearLayout.LayoutParams(0, dp(48), 1));

        buttons.addView(btn("Clear", new View.OnClickListener() {
            @Override public void onClick(View v) { clearNote(); }
        }), new LinearLayout.LayoutParams(0, dp(48), 1));

        root.addView(buttons, new LinearLayout.LayoutParams(-1, -2));
        setContentView(root);
    }

    @Override
    protected void onPause() {
        super.onPause();
        saveNote(false);
    }

    private Button btn(String text, View.OnClickListener listener) {
        Button b = new Button(this);
        b.setText(text);
        b.setAllCaps(false);
        b.setTextSize(14);
        b.setOnClickListener(listener);
        return b;
    }

    private void saveNote(boolean showToast) {
        prefs.edit().putString(KEY_NOTE, editor.getText().toString()).apply();
        if (showToast) toast("Saved");
    }

    private void copyNote() {
        String note = editor.getText().toString();
        ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        cm.setPrimaryClip(ClipData.newPlainText("BIJOY Note", note));
        toast("Copied");
    }

    private void shareNote() {
        String note = editor.getText().toString();
        Intent send = new Intent(Intent.ACTION_SEND);
        send.setType("text/plain");
        send.putExtra(Intent.EXTRA_TEXT, note);
        startActivity(Intent.createChooser(send, "Share note"));
    }

    private void clearNote() {
        editor.setText("");
        saveNote(true);
    }

    private void toast(String text) {
        Toast.makeText(this, text, Toast.LENGTH_SHORT).show();
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }
}
