import { NavigationTitleBuilder } from '../../common/builders';
import { SENSOR_NAME_LIST, SensorName } from '../../common/constants';
import { themeManager } from '../../manager';
import { deviceInfo } from '@kit.BasicServicesKit';
import { JSON, process } from '@kit.ArkTS' //
import dayjs from 'dayjs'; // 导入 dayjs 核心包
import duration from 'dayjs/plugin/duration'; // 导入 duration 运行时长插件
import { connection } from '@kit.NetworkKit';
import { display } from '@kit.ArkUI';
import { sensor } from '@kit.SensorServiceKit';
import map from '@hms.core.map.map';

dayjs.extend(duration) // 注册 duration 运行时长插件 能够使用 duration 相关的操作


@Entry
@Component
struct HardwareIndexPage {
  // 产品名称
  @State marketName: string = '-'
  // 系统版本
  @State osFullName: string = '-'
  // 系统软件API版本
  @State sdkApiVersion: string = '-'
  // 设备类型
  @State deviceType: string = '-'
  // 获取当前系统已运行的秒数
  @State uptime: number = 0
  // 网络类型
  @State netBearType: string = '-'
  // IP 地址
  @State IPAddress: string = '0.0.0.0'
  // 子网掩码
  @State subnetMask: string = '0.0.0.0'
  // 广播地址
  @State broadcastAddress: string = '0.0.0.0'
  // 屏幕分辨率（像素）
  @State displayHeight: number = 0
  @State displayWidth: number = 0
  // 屏幕刷新率（Hz）
  @State displayRefreshRate: number = 0
  // 像素密度（PPI）
  @State displayDensityDPI: number = 0
  // 支持的传感器id列表
  @State supportSensorIds: number[] = []

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  aboutToAppear(): void {
    this.getDeviceInfo()
    this.getProcessUptime()
    // this.getConnection()
    this.getConnectionNetBearType()
    this.getConnectioonProperties()
    this.getDisplayInfo()
    this.getSensorList()
  }

  getDeviceInfo() {
    this.marketName = deviceInfo.marketName //产品名称
    this.osFullName = deviceInfo.osFullName //系统版本
    this.sdkApiVersion = deviceInfo.sdkApiVersion.toString() //系统软件API版本
    this.deviceType = deviceInfo.deviceType //设备类型
  }

  //获取进程相关信息
  getProcessUptime() {
    this.uptime = process.uptime() //获取系统运行多少时间，单位（秒）
  }

  //计算启动时间，YYYY-MM-DD HH:mm:ss
  formatToDateTime(seconds: number) {
    //根据减去秒数计算启动时间，返回dayjs对象
    const dayInstance = dayjs().subtract(seconds, 'seconds')
    //格式化dayjs对象
    return dayInstance.format('YYYY-MM-DD HH:mm:ss')
  }

  //计算运行时长:D天HH小时mm分
  formatToDate(seconds: number) {
    //可以使用 dayjs.duration() 方法创建一个时长对象。这个方法接受两个参数：
    //第一个是时间长度（可以是毫秒、秒、分钟、小时、天、周、月或年），第二个是时间单位
    const dayjsInstance = dayjs.duration(seconds, 'seconds')
    return dayjsInstance.format('D天HH小时mm分')
  }

  //获取网络类型
  getConnection() {
    //检测是否有默认连接的网络
    const hasDefaultNet = connection.hasDefaultNetSync()
    //没有网络
    if (!hasDefaultNet) {
      this.netBearType = '无网络'
    } else {
      this.netBearType = '有网络'
    }
  }

  //获取网络类型
  getConnectionNetBearType() {
    //1.获取默认网络
    const defaultNet = connection.getDefaultNetSync()
    //2.获取网络信息能力
    const netCapabilities = connection.getNetCapabilitiesSync(defaultNet)
    //3.判断网络类型
    if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
      //模拟器为以太网络
      this.netBearType = '以太网网络'
    } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
      this.netBearType = 'WIFI网络'
    } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
      this.netBearType = '蜂窝网络'
    }
  }

  //获取链路信息
  getConnectioonProperties() {
    const defaultNet = connection.getDefaultNetSync()
    //获取网络的连接信息
    const connectionProperties = connection.getConnectionPropertiesSync(defaultNet)
    //提取链路信息
    const linkAddresses = connectionProperties.linkAddresses?.[0]
    if (linkAddresses) {
      //提取IP地址
      this.IPAddress = linkAddresses.address.address
    }
  }

  //获取屏幕分辨率
  getDisplayInfo() {
    //获取当前默认的display对象
    const defaultDisplay = display.getDefaultDisplaySync()
    // 屏幕分辨率（像素）
    this.displayWidth = defaultDisplay.width
    this.displayHeight = defaultDisplay.height
    // 屏幕刷新率（HZ）
    this.displayRefreshRate = defaultDisplay.refreshRate
    // 像素密度（PPI）
    this.displayDensityDPI = defaultDisplay.densityDPI
  }

  //获取传感器信息
  async getSensorList() {
    //获取设备上所有传感器信息
    const sensorList = sensor.getSensorListSync()
    AlertDialog.show({ message: JSON.stringify(sensorList, null, 2) })
    this.supportSensorIds = sensorList.map(item => item.sensorId)
  }

  @Builder
  ListTitle(title: string) {
    Text(title)
      .fontSize(16)
      .fontWeight(500)
      .fontColor($r('app.color.font'))
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 20,
        bottom: 10
      })
      .backgroundColor($r('app.color.white'))
  }

  build() {
    Navigation() {
      // 顶部硬件信息
      Column({ space: 20 }) {
        Text(this.marketName)
          .fontSize(16)
          .fontColor($r('app.color.white'))
        Column({ space: 10 }) {
          Text('系统版本：' + this.osFullName)
            .fontSize(12)
            .fontColor($r('app.color.white'))
          Text('API 版本：' + this.sdkApiVersion)
            .fontSize(12)
            .fontColor($r('app.color.white'))
          Text('设备类型：' + this.deviceType)
            .fontSize(12)
            .fontColor($r('app.color.white'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 30,
        bottom: 30
      })
      .alignItems(HorizontalAlign.Start)

      // 其他内容
      Column() {
        List() {
          ListItemGroup({ header: this.ListTitle('基本信息') }) {
            ListRow({ title: '上次启动', value: this.formatToDateTime(this.uptime) })
            ListRow({ title: '运行时间', value: this.formatToDate(this.uptime) })
          }

          ListItemGroup({ header: this.ListTitle('网络信息') }) {
            ListRow({ title: '网络类型', value: this.netBearType })
            ListRow({ title: 'IP地址', value: this.IPAddress })
            ListRow({ title: '子网掩码', value: this.subnetMask })
            ListRow({ title: '广播地址', value: this.broadcastAddress })
          }

          ListItemGroup({ header: this.ListTitle('硬件特性') }) {
            // 屏幕信息
            ListRow({ title: '屏幕分辨率（像素）', value: `${this.displayHeight}x${this.displayWidth}` })
            ListRow({ title: '屏幕刷新率（Hz）', value: this.displayRefreshRate })
            ListRow({ title: '像素密度（PPI）', value: this.displayDensityDPI })
            // 传感器信息
            ForEach(SENSOR_NAME_LIST, (item: SensorName) => {
              ListRow({
                title: item.sensorName,
                value: this.supportSensorIds.includes(item.sensorId) ? '有' : '-'
              })
            })
          }
        }
        .divider({ strokeWidth: 10 })
        .sticky(StickyStyle.Header)
        .height('100%')
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
      .borderRadius({ topLeft: 12, topRight: 12 })
      .clip(true)
    }
    .title(NavigationTitleBuilder('硬件信息'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.4], [$r('app.color.white'), 0.4]]
    })
  }
}

@Component
struct ListRow {
  @Prop title: string = ''
  @Prop value: string | number = ''

  build() {
    Row() {
      Text(this.title)
        .fontSize(14)
        .fontColor($r('app.color.font'))
      Text(this.value.toString())
        .fontSize(12)
        .fontColor($r('app.color.font_sub'))
    }
    .padding({ left: 20, right: 20 })
    .height(40)
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

