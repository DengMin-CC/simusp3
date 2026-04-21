# SP3 精密星历轨道/钟差误差仿真项目（SimuSp3）

## 项目概述
- 对 GNSS+LEO 联合精密 SP3 星历添加**仿真的轨道误差**（R/T/N 方向）和**钟差误差**
- 生成含误差的 SP3 产品，用于后续精密单点定位（FPPP）仿真验证
- 下游项目：F:\LeoSingle\csp3（联合 SP3 生成）
- 输入来源：csp3 产出的 whu{周}{DOY}.sp3 或 GLwhu{周}{DOY}.sp3

## 语言与风格
- 始终使用简体中文回复
- 代码注释用英文，解释说明用中文
- 修改代码时先说思路，再给代码
- 常规文件修改不需要征求用户意见，直接改即可

## 版本控制规范

### 仓库信息
- GitHub：https://github.com/DengMin-CC/simusp3
- 代理：`http://127.0.0.1:7890`（已配置在本地 git config）
- 分支：`master`

### 代码变更流程（由 Claude 全权负责）

```
1. 评估变更
   ├── 说明改动目的和影响范围
   ├── 列出受影响的文件
   └── 预期结果：不破坏已有数据复刻能力

2. 执行修改
   ├── 修改代码
   └── 先说思路，再给代码

3. 回归测试
   ├── 确认修改不改变核心计算逻辑（随机数种子、误差模型等）
   ├── 检查语法正确性（无遗漏的变量、括号匹配等）
   └── 对比修改前后的 diff，确认无意外改动

4. 提交推送
   ├── git add（仅添加改动文件）
   ├── git commit（规范的提交信息）
   └── git push
```

### 提交信息规范
- 格式：`<type>: <简述>`
- type：`init` 初始化 / `fix` 修复bug / `feat` 新功能 / `refactor` 重构 / `docs` 文档 / `opt` 优化
- 示例：`fix: readsp3.m 文件打开错误检查逻辑修正`

### 回归测试要点
- **不破坏数据复刻**：任何修改不得改变固定种子下的误差序列输出
- **不改变单位链**：SP3 km↔mm、μs↔s 的转换系数不可动
- **不改变随机种子**：RandStream 的 Seed 值不可动
- 安全修改示例：错误处理、边界检查、注释、文档、新增独立函数
- 危险修改示例：改 seed 值、改 amp/std 参数、改坐标转换公式

### 变更日志

#### 2026-04-21 批处理与性能优化（csp3 新文件）

**背景**：上游 csp3 项目生成了 GNSS+LEO 联合的新格式 SP3 文件
（whu23710_new.sp3 ~ whu23713_new.sp3，GPS 周 2371，DOY 310~313，
2901 epochs，261 颗有效卫星）。需批量添加误差。

**新文件**
- `batch_simusp3.m`：批量处理脚本，V1 行为（全卫星加误差，钟差 T/2）
  - 预计算旋转矩阵 R（EOP 固定，所有 epoch/文件共享）
  - 向量化误差叠加（消除内层 epoch 循环，~752k 次 ecef2eci 调用降为矩阵乘法）
  - 循环处理 4 个输入文件，输出 Cwhu{周}{DOY}_new.sp3

**性能优化（3 项，不影响计算结果）**
- `writesp3.m`：批量 I/O（内存构建全部输出行，单次 fwrite），消除 ~757k 次 fgetl/fprintf
- `sp3p2sp3v.m`：向量化 Lagrange 插值（预计算权重 + 窗口矩阵 + 矩阵乘法），边界历元保留逐 epoch lag() 调用
- `readsp3.m`：两遍扫描（第一遍计数 epoch 行数和解析头部，第二遍读数据），适配 csp3 非标准头部格式

**Bug 修复（5 个）**
- `sp3p2sp3v.m`：边界历元循环内多余的 `end`（原第 56 行），导致首尾 8 个 epoch 速度为 NaN，进而使 RTN 基向量和 recefe 为 NaN → 输出 SP3 位置全 NaN
- `sp3p2sp3v.m`：边界历元范围 `NoEp-3:NoEp` 修正为 `NoEp-4:NoEp`（遗漏 epoch 2897）
- `writesp3.m`：LEO 输出格式 `PL%02X`（如 PL01）修正为 `P%03d`（如 P201），与输入格式一致。
  旧格式导致 readsp3 因 `strcmp(tline(2),'L')` 跳过 LEO 行
- `readsp3.m`：`any(errmsg)` → `fid == -1`（错误检查逻辑修正）
- `writesp3.m`：`any(errmsgin) || any(errmsgout)` → `fin == -1 || fout == -1`

**验证结果**（verify_simu.m）
- 全部 261 颗卫星（30 GPS + 18 GLO + 27 GAL + 36 BDS + 150 LEO）均添加了误差
- 轨道误差各分量 RMS：dX ≈ 33mm, dY ≈ 33mm, dZ ≈ 33mm（符合 r_amp≈30mm, t_amp≈50mm, n_amp≈40mm）
- 钟差 RMS：dClk ≈ 32mm（符合 c_amp≈40mm, c_std≈6mm）
- 所有系统误差量级一致，逐历元抽查合理

**单文件处理耗时**（2901 epochs × 261 sats，D:/matlab/bin/matlab.exe -batch）
- 读取 + 速度计算：~22s
- 误差仿真：~1.1s
- 写入 SP3：~22s
- 合计：~45s/文件

---

#### 2026-04-21 初始整理（commit d46e780, 5ac812e）

**项目梳理**
- 完成全部 28 个文件分析，建立 CLAUDE.md 项目文档（324 行）
- 确认误差模型：余弦趋势 + 常数偏移 + AR(2) 有色噪声（simuar2.m）
- 确认两个版本差异：V1 全卫星添加误差，V2 仅 LEO 添加误差
- 梳理完整单位链：SP3(km/μs) ↔ 内部(m/s) ↔ 误差(m)

**Bug 修复（2 个，不影响数据复刻）**
- `sp3p2sp3v.m`：添加 `NoEp < nlag` 防御性边界检查

**版本控制建立**
- 初始化 git 仓库，.gitignore 排除 *.sp3 / *.mat / *.asv
- GitHub 仓库：https://github.com/DengMin-CC/simusp3
- 代理配置：http://127.0.0.1:7890（本地 git config）
- 两次提交已推送：init（28 文件）+ docs（版本控制规范）

**确认不修改的项目（会破坏数据复刻）**
- `simuar2.m` AR(2) 初始条件 `noise(1)=e(1)`：改为稳态初始值会改变全部噪声序列
- `c_phi = r_phi`：钟差复用径向相位是有意设计，模拟 R-C 相关性
- 随机数种子值、误差参数值、单位转换系数

---

## 目录结构与文件说明

    F:\LeoSingle\simusp3    │
    ├── simusp3.m               # [主脚本 V1] 所有卫星（GNSS+LEO）都添加轨道/钟差误差
    ├── SimuSp3_16.m            # [主脚本 V2] 仅 LEO 卫星添加轨道/钟差误差，GNSS 保持无误差
    ├── batch_simusp3.m         # [批量处理] V1 行为，预计算 R 矩阵 + 向量化误差叠加，多文件循环
    │
    ├── readsp3.m               # SP3 文件读取函数：两遍扫描，解析头部信息、epoch 数据、卫星位置/钟差
    ├── writesp3.m              # SP3 文件写入函数：批量 I/O，将含误差的数据按 SP3-c 格式输出
    ├── sp3p2sp3v.m             # SP3 位置到速度：向量化 9 阶 Lagrange 插值 + 地球自转改正求速度
    ├── simuar2.m               # 误差仿真函数：正弦趋势 + AR(2) 时间序列噪声
    ├── simugn.m                # [旧版] 误差仿真函数：正弦趋势 + 白噪声（已被 simuar2 替代）
    ├── selconf.m               # 卫星配置选择：根据 PRN 确定 SISRE 权重系数、轨道周期、系统类型
    ├── plotephe.m              # 误差结果可视化：R/T/N/C 的 RMS 柱状图 + 时间序列曲线
    ├── verify_simu.m           # [验证] 对比输入/输出 SP3，统计各卫星位置/钟差差异 RMS
    ├── debug_simu.m            # [调试] 追踪坐标变换中间值，定位 NaN 来源
    │
    ├── ecef2eci.m              # ECEF 到 ECI 坐标转换（Vallado 算法，IAU-1980）
    ├── eci2ecef.m              # ECI 到 ECEF 坐标转换（Vallado 算法，IAU-1980）
    ├── rv2rsw.m                # RTN（径向/切向/法向）坐标转换工具（辅助）
    ├── precess.m               # 岁差旋转矩阵（IAU-1980/2000）
    ├── nutation.m              # 章动旋转矩阵（IAU-1980）
    ├── sidereal.m              # 恒星时旋转矩阵
    ├── polarm.m                # 极移旋转矩阵
    ├── fundarg.m               # 基本天文参数计算（Delauany 变量）
    ├── iau80in.m               # IAU 1980 章动系数加载（读取 nut80.dat）
    ├── gmstime.m               # 格林尼治平恒星时计算（MJD 输入）
    ├── gstime.m                # 格林尼治恒星时计算（JD 输入，Vallado 原始版本）
    ├── lag.m                   # 10 阶 Lagrange 插值函数
    ├── unit.m                  # 向量单位化
    ├── mag.m                   # 向量求模
    ├── matvecmult.m            # 矩阵x向量乘法
    ├── nut80.dat               # IAU 1980 章动系数表（106 组系数）
    │
    ├── start-claude-glm.cmd    # Claude Code 启动脚本（GLM 模型）
    │
    ├── whu22924.sp3            # [输入] 联合 SP3（GPS 周 2292, DOY 348, 30s, GNSS+LEO 无误差）
    ├── whu23710_new.sp3        # [输入] csp3 新格式（GPS 周 2371, DOY 310, 2901 epochs, 261 sats）
    ├── whu23711_new.sp3        # [输入] DOY 311
    ├── whu23712_new.sp3        # [输入] DOY 312
    ├── whu23713_new.sp3        # [输入] DOY 313
    ├── GLwhu22924.sp3          # [输入] 融合 CLK 后的联合 SP3（GNSS 钟差精确）
    ├── Cwhu22924.sp3           # [输出] 所有卫星添加误差后的 SP3（由 simusp3.m 生成）
    ├── Cwhu23710_new.sp3       # [输出] csp3 新格式含误差（由 batch_simusp3.m 生成）
    ├── Cwhu23711_new.sp3       # [输出] DOY 311 含误差
    ├── Cwhu23712_new.sp3       # [输出] DOY 312 含误差
    ├── Cwhu23713_new.sp3       # [输出] DOY 313 含误差
    ├── CGLwhu22924.sp3         # [输出] GL 版本含误差（SimuSp3_16.m，仅 LEO 添加误差）
    ├── Swhu22924.sp3           # [中间] 疑为原始/备份的 SP3
    │
    ├── 只添加低轨钟差误差/      # [输出目录] SimuSp3_16.m 的输出结果
    │   └── Cwhu22924.sp3
    │
    └── 所有卫星钟差都添加/      # [输出目录] simusp3.m 的输出结果
        └── Cwhu22924.sp3

### 文件命名规则
- whu{周}{DOY}.sp3: 输入无误差联合 SP3，来自上游 csp3 项目
- whu{周}{DOY}_new.sp3: csp3 新格式输入，来自上游 csp3 项目（GNSS+LEO 联合）
- GLwhu{周}{DOY}.sp3: 输入融合 CLK 的联合 SP3，来自上游 csp3 项目
- Cwhu{周}{DOY}.sp3: 输出所有卫星含误差的 SP3，由 simusp3.m 生成
- Cwhu{周}{DOY}_new.sp3: csp3 新格式输出，由 batch_simusp3.m 生成
- CGLwhu{周}{DOY}.sp3: 输出仅 LEO 含误差的 SP3，由 SimuSp3_16.m 生成
- Swhu{周}{DOY}.sp3: 备份/中间文件
---

## 核心算法与工作流程

### 总体流程

    输入 SP3 (whu22924.sp3 / GLwhu22924.sp3)
            |
            v
        readsp3.m  -->  sp3p 结构体（位置 + 钟差，ECEF，m/s）
            |
            v
        sp3p2sp3v.m  -->  sp3v 结构体（速度，ECEF，通过 Lagrange 插值）
            |
            v
      +-------------------------------------+
      |  对每颗有效卫星 j = 1:MaxSat       |
      |                                     |
      |  1. selconf(j) -> SISRE 权重 + T    |
      |  2. simuar2() x 4 次 -> R/T/N/C 误差|
      |  3. ECEF -> ECI 坐标转换             |
      |  4. 在 ECI 中构建 RTN 基向量        |
      |  5. 将 RTN 误差叠加到轨道           |
      |  6. ECI -> ECEF 坐标转换回           |
      |  7. 钟差误差叠加                    |
      +-------------------------------------+
            |
            v
        writesp3.m  -->  输出含误差的 SP3 文件
            |
            v
        plotephe.m  -->  误差统计可视化（可选）

### 步骤一：读取输入 SP3（readsp3.m）

- 解析 SP3-c 格式文件头：起始时间、epoch 数量、采样间隔、卫星列表
- 按系统分配内部编号：
  - GPS：G01 -> 编号 1~NsatGPS
  - GLONASS：R01 -> 编号 NsatGPS+1 ~ NsatGPS+NsatGLO
  - Galileo：E01 -> 编号 NsatGPS+NsatGLO+1 ~ ...
  - BDS：C01 -> 编号 NsatGPS+NsatGLO+NsatGAL+1 ~ ...
  - LEO：201~350 -> 编号 NsatGPS+NsatGLO+NsatGAL+NsatCMP+1 ~ ...
- 位置单位：SP3 中为 km，读取后转为米（×1000）
- 钟差单位：SP3 中为微秒，读取后转为秒（×10^-6）
- 输出结构体 sp3p：recef[epoch, 4, sat]（x,y,z 单位 m，clk 单位 s）

### 步骤二：计算速度（sp3p2sp3v.m）

- 使用 10 点（9 阶）Lagrange 插值在时间上微扰（dt=0.001s）后求差商
- 关键：对 x/y 分量先做地球自转改正（绕 z 轴旋转 we*dt），再插值
- z 分量不受地球自转影响，直接插值
- 输出 sp3v.vecef[epoch, 3, sat]，单位 m/s

### 步骤三：误差仿真（simuar2.m + selconf.m）

#### 3.1 误差模型（simuar2.m）

每颗卫星的每个误差分量（R/T/N/C）独立仿真，模型为：

    error(t) = A*cos(wt + phi) + d + AR(2) 噪声

其中：
- A：振幅（每颗卫星不同，由全局均值 + 高斯随机偏差生成）
- w = 2pi/T：角频率，T 为轨道周期（由 selconf.m 根据卫星高度计算）
- phi：初相位（0~2pi 均匀随机）
- d：常数偏移（高斯随机）
- AR(2) 噪声：noise(i) = 0.6*noise(i-1) + 0.25*noise(i-2) + e(i)
  - e(i) 为白噪声，标准差经过缩放以使总 AR(2) 序列标准差 = sig
  - 每颗卫星使用固定种子（sat 参数），保证可重复性

#### 3.2 卫星配置参数（selconf.m）

| 系统 | 卫星数 | 轨道高度 | w_r（径向权重） | w_ac2（切向/法向权重） |
|------|--------|---------|----------------|---------------------|
| GPS | 32 | 20180 km | 0.98 | 1/49 |
| GLONASS | 27 | 19100 km | 0.98 | 1/45 |
| Galileo | 52 | 23220 km | 0.98 | 1/61 |
| BDS GEO/IGSO | 部分 | 35786 km | 0.99 | 1/126 |
| BDS MEO | 部分 | 21528 km | 0.98 | 1/54 |
| LEO | 150 | 1100 km | ~0.582（样条插值） | ~0.575 |

- LEO 的 w_r 和 w_ac2 由 6 个高度节点（400~1400 km）通过样条插值得到
- 轨道周期：T = T_gso * ((Re+h)/(Re+h_gso))^(3/2)，T_gso = 86164s
- BDS 子类型判断：PRN <= 10 或特定 PRN（13,16,31,38,39,40,56,59+）为 GEO/IGSO

#### 3.3 当前误差参数配置（2024-03-06 调整）

| 参数 | 径向 (R) | 切向 (T) | 法向 (N) | 钟差 (C) |
|------|---------|---------|---------|---------|
| 振幅均值 (amp_avg) | 3.0 cm | 5.0 cm | 4.0 cm | 4.0 cm |
| 振幅标准差 (amp_std) | 0.3 cm | 0.3 cm | 0.3 cm | 0.3 cm |
| 白噪声标准差 (std) | 1.0 cm | 1.0 cm | 1.0 cm | 0.6 cm |
| 偏移均值 (disp_avg) | 0 | 0 | 0 | 0 |
| 偏移标准差 (disp_std) | 0.5 cm | 2.0 cm | 1.0 cm | 1.5 cm |
| 趋势周期 | T（轨道周期） | T | T | T/2（V2 中为 T） |

注：旧版配置（注释中）amp_avg=7.0cm，已调整为 3~5cm 以匹配实测 FPPP 精度。

### 步骤四：误差叠加到轨道

对每个 epoch、每颗卫星：
1. ECEF -> ECI：将位置和速度从地球固定系转到惯性系
2. 构建 RTN 基向量（在 ECI 中）：
   - 径向 R：r_hat = r/|r|
   - 法向 N：n_hat = (r x v)/|r x v|
   - 切向 T：t_hat = n_hat x r_hat
3. 叠加误差：r_eci_new = r_eci + G^T * [dR; dT; dN]（G = [R_hat; T_hat; N_hat]）
4. ECI -> ECEF：转换回地球固定系
5. 叠加钟差：clk_new = clk_old + dC / c（dC 单位为米，除以光速转为秒）

### 步骤五：写入输出 SP3（writesp3.m）

- 逐行复制输入 SP3 的头部（#、+、%、/ 开头的行）
- 对每个 epoch 的每颗卫星，用含误差的数据替换原始数据
- 位置：m -> km（/1000）
- 钟差：秒 -> 微秒（×10^6）
- LEO 卫星标识符格式：P + 3 位十进制编号（如 P201），与输入格式一致

### 步骤六：结果可视化（plotephe.m）

- 图 1（5 子图）：所有卫星的 R/T/N/C RMS 柱状图 + SISRE 柱状图
  - X 轴标注各系统首颗卫星（G01, R01, E01, C01, L001, L149）
  - SISRE 分别统计 GNSS 和 LEO 的均值
- 图 2（4 子图）：选取 C19（BDS）和 L001（LEO）的误差时间序列
  - 展示 24 小时内的 R/T/N/C 误差变化趋势
---

## 两个版本的差异

| 特性 | simusp3.m（V1） | SimuSp3_16.m（V2） |
|------|----------------|-------------------|
| 输入 | whu22924.sp3 | GLwhu22924.sp3 |
| 误差添加范围 | 所有卫星（GNSS + LEO） | 仅 LEO 卫星（j >= 173） |
| GNSS 卫星 | 添加误差 | 不添加误差（全零） |
| 钟差趋势周期 | T/2（半轨道周期） | T（完整轨道周期） |
| 输出前缀 | C | CGL |
| 用途 | 全系统误差仿真 | 仅 LEO 误差仿真（GNSS 使用 WUM 精密产品） |

V1 中跳过 GNSS 的方法（已注释）：在 SimuSp3_16.m 中启用 if j<173 代码块即可。

V2 中关闭 T/2 的方法（已注释）：在 simusp3.m 中启用 T=T/2 即可。

---

## SISRE 计算公式

    SISRE = sqrt( mean((w_r * dR - dC)^2) + w_ac^2 * (mean(dT^2) + mean(dN^2)) )

- w_r：径向权重（GNSS 约 0.98，LEO 约 0.58）
- w_ac2 = w_ac^2：切向/法向权重平方
- 径向误差与钟差高度相关（w_r*dR - dC 项），切向/法向独立

---

## 当前配置状态

### 已处理的 SP3 文件

| 输入文件 | 输出文件 | 脚本 | 说明 |
|---------|---------|------|------|
| whu22924.sp3 | Cwhu22924.sp3 | simusp3.m | V1 所有卫星添加误差 |
| whu22925.sp3 | Cwhu22925.sp3 | simusp3.m | DOY 349 |
| whu22926.sp3 | Cwhu22926.sp3 | simusp3.m | DOY 350 |
| whu23710_new.sp3 | Cwhu23710_new.sp3 | batch_simusp3.m | csp3 新格式，261 sats |
| whu23711_new.sp3 | Cwhu23711_new.sp3 | batch_simusp3.m | DOY 311 |
| whu23712_new.sp3 | Cwhu23712_new.sp3 | batch_simusp3.m | DOY 312 |
| whu23713_new.sp3 | Cwhu23713_new.sp3 | batch_simusp3.m | DOY 313 |
| GLwhu22924.sp3 | CGLwhu22924.sp3 | SimuSp3_16.m | V2 仅 LEO 添加误差 |

### 卫星数量配置

| 系统 | 变量 | 数量 |
|------|------|------|
| GPS | NsatGPS | 32 |
| GLONASS | NsatGLO | 27 |
| Galileo | NsatGAL | 52 |
| BDS | NsatCMP | 61 |
| LEO | NsatLEO | 150 |
| 合计 | MaxSat | 322 |

### 时间参考参数（硬编码于主脚本）

| 参数 | 值 | 说明 |
|------|-----|------|
| leapsec | 18.0 | GPS-UTC 闰秒 |
| ut1_utc | 122353e-7 s | UT1-UTC |
| tt_gps | 51.184 s | TT-GPS (= 32.184 + 19.0) |
| jdgps | 2460292.5 | GPST 2019-03-31 00:00:00 的 JD |
| ttt | (jdtt-2451545)/36525 | TT 的儒略世纪数 |
| lod | -4047e-7 s | 日长变化 |
| xp/yp | 187693/206272 e-6 arcsec | 极移参数 |
| eqeterms | 2 | 恒星时方程项数 |
| hleo | 1100 km | LEO 轨道高度 |
---

## 注意事项和踩坑记录

### 1. 随机数可重复性
- 所有随机数生成使用 RandStream(mcgsomething, Seed, xxx) 固定种子
- R/T/N/C 的振幅、相位、偏移各有独立种子段（10001/20001/30001 等）
- 每颗卫星在 simuar2 中使用 sat 参数（= j + MaxSat * 方向编号）作为种子
- 同一种子永远产生相同误差序列，便于对比实验

### 2. ECI 坐标转换参数
- 主脚本中 ECEF 到 ECI 转换使用固定的地球定向参数（xp, yp, lod 等）
- 这些参数对应 2019-03-31，与实际 SP3 数据时间（2023-12-14）不一致
- 影响：ECEF->ECI->叠加误差->ECI->ECEF 的过程引入了坐标转换误差
- 但由于仅用于构建 RTN 基向量，且 RTN 误差量级为 cm，转换误差影响可忽略

### 3. SP3 位置单位链（易混淆）
- SP3 文件中位置单位为 km
- readsp3.m 读取时 ×1000 → 米（不是毫米！代码中变量名含 _mm 后缀是历史遗留，实际为 m）
- simuar2.m 返回的误差单位为米（r_amp≈0.030 即 30mm）
- writesp3.m 写入时 /1000 → km
- 完整链：SP3(km) → ×1000 → 内部(m) → 误差叠加(m) → /1000 → SP3(km)

### 4. SP3 钟差单位链
- SP3 文件中钟差单位为微秒
- readsp3.m 读取时 x10^-6 -> 秒
- simusp3.m 中钟差误差 dC 单位为米
- 叠加时：clk_new(s) = clk_old(s) + dC(m) / c(m/s) -> 秒
- writesp3.m 写入时 x10^6 -> 微秒

### 5. 主脚本会删除 .mat 和 .asv 文件
- simusp3.m 和 SimuSp3_16.m 开头有 delete(*.mat); delete(*.asv);
- 运行前会清除所有中间结果，如需保留需提前备份

### 6. 卫星有效性检查
- 主循环中通过 isnan(sum(sp3p.recef(1440,1:4,j))) 判断卫星是否存在
- 硬编码检查第 1440 个 epoch（12:00:00），该 epoch 无数据则跳过
- 适用于 2880 epoch（24h, 30s 间隔）或 2899 epoch 的 SP3

### 7. GLwhu 与 whu 输入差异
- whu22924.sp3：epoch 起始于前一天 23:55，共 2899 个 epoch
- GLwhu22924.sp3：epoch 起始于当天 00:00，共 2880 个 epoch
- 两者卫星列表相同（261 颗），但时间范围不同
- writesp3.m 通过匹配 epoch 时间字符串来对齐，输入输出必须使用相同起止时间的 SP3

### 8. 钟差偏移符号修正
simusp3.m 第 127-131 行：当 |c_disp - r_disp| > |c_disp| 时，c_dispuse = -c_disp，
目的是使钟差偏移与径向偏移符号相反，模拟径向-钟差相关性。
SimuSp3_16.m（V2）中没有此修正，直接使用 c_disp。

### 9. BDS 卫星分类
- selconf.m 中 BDS 的 GEO/IGSO 判断基于 PRN 编号
- PRN <= 10 或 PRN 为 13,16,31,38,39,40,56,59+ -> GEO/IGSO（w_r=0.99, 高轨道）
- 其余 -> MEO（w_r=0.98, 中轨道）
- 实际 WUM 产品中 BDS 卫星 PRN 可能不连续，需确认

### 10. simugn.m vs simuar2.m
- simugn.m：旧版，使用已废弃的 RandStream API + 纯白噪声
- simuar2.m：当前版本，使用新 RandStream API + AR(2) 有色噪声
- AR(2) 噪声更真实，能模拟误差的时间相关性

### 11. plotephe.m 中的轴范围硬编码
- X 轴范围 [1 267]、Y 轴范围 [0 10] 等均为固定值
- 当卫星数量或误差量级变化时，图形可能截断
- 第 90 行卫星编号标注 C19 对应第 90 颗卫星（G32 后的 BDS），需确认是否正确

### 12. sp3p2sp3v.m 边界历元 NaN 传播链
- 边界历元（首尾各 4-5 个 epoch）的速度通过逐 epoch 的 lag() 插值计算
- 若该循环被提前终止（如多余的 `end`），速度保持 NaN 初始化值
- NaN 速度 → NaN veci → NaN RTN 基向量 → NaN xyz → NaN recefe → 输出 SP3 位置全 NaN
- 钟差不经过坐标变换，不受影响（输出 NaN 位置 + 有效钟差是此 bug 的特征）

### 13. writesp3.m LEO 格式与 readsp3.m 的匹配
- 输入文件 LEO 格式：`P201`（P + 3 位十进制数，第 2 字符为数字）
- readsp3.m 的 else 分支通过 `sscanf(tline(2:4),'%d')` 读取 201
- 若 writesp3 输出 `PL01` 格式，readsp3 因 `strcmp(tline(2),'L')` 跳过该行
- 必须保持输入/输出的 LEO 格式一致（都用 P + 3 位编号）

### 14. csp3 新格式 SP3 与旧格式差异
- csp3 生成的 SP3 秒字段多一个空格（`0 0.00000000` vs `0.00000000`），导致列偏移
- `#a` 行包含卫星数（261）而非 epoch 数，不能依赖固定列位置解析 NoEp
- 解决方案：readsp3 两遍扫描，第一遍统计 `*` 行数确定 NoEp