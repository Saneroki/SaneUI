-- Core: Sane UI's Core from its TOC, with its window to try windows with (/sane window; rest the mouse on it)
-- What Core's guards catch shows in the log as errors (the lab reads Core's error log).
Lab.TOC("src/Core/SaneUI.toc")
Lab.OnLogin(function() Lab.Slash("/sane window") end)
