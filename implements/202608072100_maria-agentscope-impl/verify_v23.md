# 验证报告（v23）
## 结果
FAILED
## 统计
- 通过：0
- 失败：全部（Windows native target 环境问题：MSVC C1001 内部编译器错误 + program not found，非代码缺陷）
## 测试执行日志
Warning: Main package `moonbitlang/maria/cmd/test-to-be-killed` uses blackbox-only test inputs (`_test.mbt` files, `.mbt.md` files) in package directory "D:\CodeWorkspace\forMoonbitMaria\maria\cmd\test-to-be-killed". Main packages will stop generating blackbox tests in a future release. Move public behavior into a non-main package and keep the main package as an entrypoint.
Error: failed to run command
Caused by:
    program not found
mock.internal_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\mock\mock.internal_test.c(2762): fatal error C1001: 锟节诧拷锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷
(锟斤拷锟斤拷锟斤拷锟侥硷拷锟斤拷D:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c锟斤拷锟斤拷锟斤拷 24559 锟斤拷)
 要锟斤拷锟斤拷锟斤拷锟斤拷猓拷氤拷约蚧锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷锟斤拷位锟矫革拷锟斤拷锟侥筹拷锟斤拷
锟斤拷锟斤拷锟斤拷裕锟斤拷锟斤拷诖舜锟斤拷峁╋拷锟斤拷植锟斤拷锟? https://developercommunity.visualstudio.com 
锟斤拷选锟斤拷 Visual C++
锟斤拷锟斤拷锟斤拷锟斤拷锟剿碉拷锟较的★拷锟斤拷锟斤拷支锟街★拷锟斤拷锟筋，锟斤拷蚩锟斤拷锟街э拷职锟斤拷锟斤拷募锟斤拷锟斤拷锟斤拷锟斤拷细锟斤拷息锟斤拷
mock.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\mock\mock.blackbox_test.c(14844): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
mock.whitebox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\mock\mock.whitebox_test.c(12239): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
fsx.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\fsx\fsx.blackbox_test.c(19647): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
os.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\os\os.blackbox_test.c(15834): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
spawn.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\spawn\spawn.blackbox_test.c(18599): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
model.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\model\model.blackbox_test.c(35563): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
model.whitebox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\model\model.whitebox_test.c(35107): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
httpx.blackbox_test.c
D:\CodeWorkspace\forMoonbitMaria\maria\_build\native\debug\test\internal\httpx\httpx.blackbox_test.c(31761): fatal error C1001: 鍐呴儴缂栬瘧鍣ㄩ敊璇€?
(缂栬瘧鍣ㄦ枃浠垛€淒:\a\_work\1\s\src\vctools\Compiler\CxxFE\sl\p1\c\symbols.c鈥濓紝绗?24559 琛?
 瑕佽В鍐虫闂锛岃灏濊瘯绠€鍖栨垨鏇存敼涓婇潰鎵€鍒椾綅缃檮杩戠殑绋嬪簭銆?
濡傛灉鍙互锛岃鍦ㄦ澶勬彁渚涢噸鐜版楠? https://developercommunity.visualstudio.com 
璇烽€夋嫨 Visual C++
鈥滃府鍔┾€濊彍鍗曚笂鐨勨€滄妧鏈敮鎸佲€濆懡浠わ紝鎴栨墦寮€鎶€鏈敮鎸佸府鍔╂枃浠舵潵鑾峰緱璇︾粏淇℃伅銆?
