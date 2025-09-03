import React from 'react';
import { View, Text, Button, Image, StyleSheet } from 'react-native';
import { useTheme } from '../hooks/useTheme';
import { Colors } from '../constants/Colors';

export default function Welcome() {
  const { theme, toggleTheme } = useTheme();

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: Colors[theme].background,
    },
    text: {
      color: Colors[theme].text,
      fontSize: 24,
      marginBottom: 20,
    },
    logo: {
      width: 200,
      height: 100,
      resizeMode: 'contain',
      marginBottom: 20,
    },
  });

  return (
    <View style={styles.container}>
      <Image
        source={
          theme === 'light'
            ? require('../assets/logo_name_light.png')
            : require('../assets/logo_name_dark.png')
        }
        style={styles.logo}
      />
      <Text style={styles.text}>Welcome to the app!</Text>
      <Button title="Toggle Theme" onPress={toggleTheme} />
    </View>
  );
}
