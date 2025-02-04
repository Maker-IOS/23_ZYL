import { Permissions } from '@kit.AbilityKit';
import { NavigationTitleBuilder } from '../../common/builders';
import { permissionManager, themeManager } from '../../manager';
import json from '@ohos.util.json';
import { JSON } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';
import { it } from '@ohos/hypium';
import { notificationManager } from '@kit.NotificationKit';

interface PermissionItem {
  name: string
  title: string
  desc: string
  permissions: Permissions[]
  timeStamp: number // 用于更新授权状态
}

// 权限管理设置页
@Entry
@Component
struct SettingsPermissionPage {
  @State isNotificationEnabled: boolean = false
  @State permissionList: PermissionItem[] = [
    {
      name: 'notification',
      title: '通知',
      desc: '开启后可以获得安全播报，号码包升级等',
      permissions: [],
      timeStamp: 0
    },
    // 对所有应用开放的权限
    {
      name: 'camera',
      title: '相机',
      desc: '开启后才能使用安全扫码等功能',
      permissions: ['ohos.permission.CAMERA'],
      timeStamp: 0
    },
    {
      name: 'microphone',
      title: '麦克风',
      desc: '开启后才能录制加密视频和音频',
      permissions: ['ohos.permission.MICROPHONE'],
      timeStamp: 0
    },
    {
      name: 'calendar',
      title: '日历',
      desc: '开启后才能帮您清理诈骗日历、过期日历',
      permissions: ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'],
      timeStamp: 0
    },
    {
      name: 'location',
      title: '位置',
      desc: '开启后精准显示空气指数，识别骚扰号码更加精准',
      permissions: ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'],
      timeStamp: 0
    },
    // 允许ACL跨级别申请的权限
    {
      name: 'image_video',
      title: '照片',
      desc: '开启后才能帮您通过照片瘦身节省空间',
      permissions: ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO'],
      timeStamp: 0
    },
    {
      name: 'contacts',
      title: '通讯录',
      desc: '开启后才能帮您进行通讯录的备份、恢复和优化',
      permissions: ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'],
      timeStamp: 0
    },
  ]

  onPageShow() {
    themeManager.settingStatusBarWhite()
    // 页面显示 更新权限列表
    this.updatePermission()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  // 申请权限
  async requestPermission(item: PermissionItem) {
    // 1.申请权限
    try {
      await permissionManager.requestPermissions(item.permissions)
      // 允许 -> 变成text文本
    } catch (error) {
      // 禁止 -> 引导用户打开设置页开启权限
      // AlertDialog.show({ message: JSON.stringify(error, null, 2) })
      promptAction.showDialog({
        alignment: DialogAlignment.Center,
        title: '温馨提示',
        message: item.desc,
        buttons: [
          { text: '取消', color: '#89939c' },
          { text: '去设置', color: '#0a59f7' },
        ]
      })
        .then((res) => {
          //用户点击了去设置
          if (res.index === 1) {
            //通过代码打开当前应用的设置页
            permissionManager.openPermissionSettingsPage()
          }
        })
    }
    // 更新权限列表
    this.updatePermission()
  }

  // 更新权限列表 时间戳改变让list循环渲染
  updatePermission() {
    this.permissionList = this.permissionList.map<PermissionItem>((item) => {
      return {
        name: item.name,
        title: item.title,
        desc: item.desc,
        permissions: item.permissions,
        timeStamp: Date.now(),
      }
    })
  }

  //关闭权限 鸿蒙没有关闭权限的api 要用户自行到设置页关闭
  closePermission() {
    promptAction.showDialog({
      alignment: DialogAlignment.Center,
      title: '温馨提示',
      message: '关闭权限会影响应用的正常运行，您确定关闭吗？',
      buttons: [
        { text: '取消', color: $r('app.color.brand') },
        { text: '关闭', color: $r('app.color.font_sub') },
      ]
    })
      .then((res) => {
        //用户点击了去设置
        if (res.index === 1) {
          //通过代码打开当前应用的设置页
          permissionManager.openPermissionSettingsPage()
        }
      })
  }

  // 更新授权状态
  async updatePermissionState() {
    // 是否开启通知
    this.isNotificationEnabled = await notificationManager.isNotificationEnabled()
  }

  build() {
    Navigation() {
      Row() {
        Text('建议您开启全部权限\n体验小卫更精准、更贴心的功能！')
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .lineHeight(20)
          .textAlign(TextAlign.Center)
      }
      .height(180 - 56)

      Column() {
        ForEach(this.permissionList, (item: PermissionItem) => {
          Row() {
            Column({ space: 5 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(500)
                .fontColor($r('app.color.font'))
              Text(item.desc)
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
            .alignItems(HorizontalAlign.Start)

            // TODO: 检测权限是否开启
            if (item.name === 'notification') {
              if (this.isNotificationEnabled) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                Toggle({ type: ToggleType.Switch, isOn: false })// 组件提供勾选框样式、状态按钮样式及开关样式
                  .onChange(async () => {
                    // TODO：点击申请 notification 权限
                    try {
                      // 授权弹窗
                      await notificationManager.requestEnableNotification()
                    } catch (error) {
                      // 打开设置页
                      permissionManager.openPermissionSettingsPage()
                    }
                    // 更新所有权限授权状态
                    this.updatePermissionState()
                  })
              }
            } else {
              if (permissionManager.checkPermissions(item.permissions)) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .onChange(async () => {
                    // TODO：点击申请 user_grant 授权
                    this.requestPermission(item)
                  })
              }
            }
          }
          .width('100%')
          .height(64)
          .justifyContent(FlexAlign.SpaceBetween)
        })
        Button('关闭权限')
          .fontColor($r('app.color.font_sub'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 20 })
          .onClick(() => {
            // TODO: 关闭权限，弹窗提示，关闭权限需到设置页关闭
            // 鸿蒙没有关闭权限的api 要用户自行到设置页关闭
            this.closePermission()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder('权限管理')) // 导航标题
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.25], [$r('app.color.white'), 0.25]]
    })
  }
}