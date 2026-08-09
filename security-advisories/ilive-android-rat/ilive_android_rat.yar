rule ILIVE_Android_RAT_Defensive_IOCs
{
    meta:
        description = "Defensive detection for analyzed ILIVE Android RAT sample"
        author = "Public defensive advisory"
        reference = "https://github.com/cryptojetsoftware000-hash/BIJOY-V1/issues/7"
        sha256 = "8c4c373b4ae09691a86525eb504205b6365c8ec9fbedb3ea190b9f60312700a3"

    strings:
        $pkg = "i422sh.wvp49.uyef.pm8qa" ascii wide
        $c2a = "chaorencctv1.com" ascii wide nocase
        $c2b = "duodaduo.com" ascii wide nocase
        $phonepe = "com.phonepe.app" ascii wide
        $adbcore = "com.system.adbcore" ascii wide
        $keylog = "/api/keylog/ingest" ascii wide
        $ocr = "/api/ocr-captcha" ascii wide
        $campaign = "apk=10028" ascii wide

    condition:
        uint32(0) == 0x04034b50 and 4 of them
}
