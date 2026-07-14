const prisma = require('../config/prisma');

async function upsertDevice(userId, device) {
  const { deviceId, deviceName, platform, fcmToken } = device;

  const existing = await prisma.device.findUnique({
    where: { userId_deviceId: { userId, deviceId } },
  });

  const record = await prisma.device.upsert({
    where: { userId_deviceId: { userId, deviceId } },
    update: {
      deviceName,
      platform,
      fcmToken,
      lastLogin: new Date(),
    },
    create: {
      userId,
      deviceId,
      deviceName,
      platform,
      fcmToken,
    },
  });

  return { device: record, isNewDevice: !existing };
}

async function updateFcmToken(userId, deviceId, fcmToken) {
  return prisma.device.update({
    where: { userId_deviceId: { userId, deviceId } },
    data: { fcmToken },
  });
}

async function listUserDevices(userId, excludeDeviceId) {
  return prisma.device.findMany({
    where: {
      userId,
      ...(excludeDeviceId ? { deviceId: { not: excludeDeviceId } } : {}),
    },
  });
}

module.exports = { upsertDevice, updateFcmToken, listUserDevices };
