import { Colors } from '@/constants/Colors';
import { useTheme } from '@/hooks/useTheme';
import React, { useEffect } from 'react';
import { Platform } from 'react-native';
import {
    PERMISSIONS,
    RESULTS,
    request,
    Permission
} from "react-native-permissions";
import { Image, SafeAreaView, StyleSheet, Text, TouchableOpacity } from 'react-native';
import { View } from 'react-native';

const Module = ({ permission, displayName }: { permission: Permission; displayName: string }) => {
    const [state, setState] = React.useState(false);

    useEffect(() => {
        request(permission).then(e => {
            if (e === RESULTS.GRANTED || e === RESULTS.LIMITED) {
                setState(true)
            } else {
                setState(false)
            }
        }).catch(e => {
            setState(false)
        })
    })

    return (<View>
        <Text>{(state == true) ? "✔️" : "❌"}</Text>
        <Text>{displayName}</Text>
    </View>)
}

const Checks = ({ done, back }: { done: () => void, back: () => void }) => {
    const { theme, toggleTheme } = useTheme();

    const styles = StyleSheet.create({
        container: {
            flex: 1,
            backgroundColor: Colors[theme].background,
            alignItems: 'center',
            justifyContent: 'center',
        },
        logo: {
            width: 200,
            height: 100,
            resizeMode: 'contain',
            marginBottom: 40,
        },
        title: {
            fontSize: 24,
            fontWeight: 'bold',
            color: Colors[theme].text,
            marginBottom: 20,
        },
        button: {
            backgroundColor: Colors[theme].tint,
            padding: 15,
            borderRadius: 10,
            marginBottom: 20,
            width: '80%',
            alignItems: 'center',
        },
        buttonText: {
            color: Colors[theme].background,
            fontSize: 18,
            fontWeight: 'bold',
        },
        toggleButton: {
            position: 'absolute',
            top: 60,
            right: 20,
            padding: 10,
            borderRadius: 5,
            backgroundColor: Colors[theme].tint,
        },
        toggleButtonText: {
            color: Colors[theme].background,
            fontSize: 16,
        },
    });

    const data = 
    Platform.OS === "ios"? [{
        permission: PERMISSIONS.IOS.BLUETOOTH,
        displayName: "Bluetooth"
    }]: [{
        permission: PERMISSIONS.ANDROID.ACCESS_COARSE_LOCATION,
        displayName: "Access Coarse Location"
  }, {
    permission:    PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION,
    displayName: "Access Fine Location"
  }, {
    permission:PERMISSIONS.ANDROID.BLUETOOTH_ADVERTISE,
    displayName: "Bluetooth Advertise"
  }, {
    permission:PERMISSIONS.ANDROID.BLUETOOTH_CONNECT,
    displayName: "Bluetooth Connect"
  }, {
    permission:PERMISSIONS.ANDROID.BLUETOOTH_SCAN,
    displayName: "Bluetooth Scan"
  }, {
    permission:PERMISSIONS.ANDROID.NEARBY_WIFI_DEVICES,
    displayName: "Nearby Wifi Devices"
  }]

    return (
        <SafeAreaView style={styles.container}>
            <Image
                source={theme === 'light' ? require('@/assets/logo_name_light.png') : require('@/assets/logo_name_dark.png')}
                style={styles.logo}
            />
            <Text style={styles.title}>NearbyFiles: Setup</Text>
            <TouchableOpacity style={styles.button} onPress={done}>
                {data.map(e => (<Module permission={e.permission} displayName={e.displayName} />))}
            </TouchableOpacity>
        </SafeAreaView>
    );
};

export default Checks;
