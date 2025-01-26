import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit'
import { JSON } from '@kit.ArkTS'
import { permissionManager } from '../../manager/PermissionManager'
import { promptAction } from '@kit.ArkUI'


@Entry
@Component
struct PermissionTestPage {
  build() {
    Navigation() {
      Column({ space: 10 }) {
        Button('检测权限')
          .onClick(() => {
            //检测是否授权
            //1.程序访问控制
            const atManager = abilityAccessCtrl.createAtManager()
            //获取tokenID的固定写法
            //2.获取bundle(应用包)信息
            const bundleInfo =
              bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
            //3.应用唯一标识，通过动态获取
            const tokenID = bundleInfo.appInfo.accessTokenId
            //4.检测权限
            const grantStatus = atManager.checkAccessTokenSync(tokenID, 'ohos.permission.READ_CALENDAR')
            AlertDialog.show({ message: JSON.stringify(grantStatus, null, 2) })
            // permissionManager.checkPermissions(['ohos.permission.READ_CALENDAR'])
          })

        Button('动态向用户申请授权')
          .onClick(async () => {
            //核心API：requestPermissionsFromUser()
            //1.程序访问控制
            const atManager = abilityAccessCtrl.createAtManager()
            //2.动态向用户申请授权
            const result = await atManager.requestPermissionsFromUser(getContext(), ['ohos.permission.READ_CALENDAR'])
            //3.处理请求权限结果
            // return result.authResults.every(v => v === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
            AlertDialog.show({ message: JSON.stringify(result, null, 2) })
            // permissionManager.requestPermissions(['ohos.permission.READ_CALENDAR'])
          })

        Button('打开设置页(处理授权失败的情况)')
          .onClick(() => {
            //as断言为UIAbilityContext,用于调用startAbility的API
            const context = getContext() as common.UIAbilityContext
            //2.获取bundle(应用包)信息
            const bundleInfo =
              bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
            //启动一个设置页(应用)
            context.startAbility({
              //固定写法
              // action: 'action.settings.app.info',
              // parameters: {
              //   settingsParamBundleName: bundleInfo.name //打开指定应用的详情页面
              // }
              bundleName: 'com.huawei.hmos.settings',
              abilityName: 'com.huawei.hmos.settings.MainAbility',
              uri: 'application_info_entry',
              parameters: {
                // 按照包名打开对应设置页
                pushParams: bundleInfo.name
              }
            })
            // permissionManager.openPermissionSettingsPage()
          })

        Button('打开设置页-调用封装')
          .onClick(() => {
            permissionManager.openPermissionSettingsPage()
          })
        Button('申请权限-调用封装')
          .onClick(
            async () => {
              const isAuth = await permissionManager.requestPermissions(['ohos.permission.READ_CONTACTS',
                'ohos.permission.WRITE_CONTACTS'])
              promptAction.showToast({ message: '能否调用权限' + isAuth })
              //权限允许后 后续可以调用相机的API了
              AlertDialog.show({ message: '现在可以调用相机API' })
            })
        Button('检测权限---调用封装')
          .onClick(() => {
            const isAuth =
              permissionManager.checkPermissions(['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'])
            AlertDialog.show({ message: JSON.stringify(isAuth, null, 2) })
          })
        Text('当前CAMERA权限为:' + permissionManager.checkPermissions(['ohos.permission.CAMERA']))
      }
    }
    .title('权限')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
  }
}