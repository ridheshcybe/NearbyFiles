import { useTheme } from '@/hooks/useTheme';
import React from 'react';
import { View, Text, Image, TouchableOpacity, StyleSheet, SafeAreaView } from 'react-native';
import { Colors } from '@/constants/Colors';

const Welcome = ({ done }: { done: () => void }) => {
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

  return (
    <SafeAreaView style={styles.container}>
      <Image
        source={theme === 'light' ? require('@/assets/logo_name_light.png') : require('@/assets/logo_name_dark.png')}
        style={styles.logo}
      />
      <Text style={styles.title}>Welcome to NearbyFiles</Text>
      <TouchableOpacity style={styles.button} onPress={done}>
        <Text style={styles.buttonText} onPress={()=>done()}>Get Started</Text>
      </TouchableOpacity>
      <TouchableOpacity style={styles.toggleButton} onPress={toggleTheme}>
        <Text style={styles.toggleButtonText}>Toggle Theme</Text>
      </TouchableOpacity>
    </SafeAreaView>
  );
};

export default Welcome;
