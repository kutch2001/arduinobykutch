
#ifndef ESP8266_h
#define ESP8266_h

#include "Stream.h"
#include "IPAddress.h"

#ifndef HAVE_HWSERIAL1
#include "SoftwareSerial.h"
#endif

#include "RingBuffer.h"


#define WL_SERIAL_SPEED 9600

// Maximum size of a SSID
#define WL_SSID_MAX_LENGTH 32

// Length of passphrase. Valid lengths are 8-63.
#define WL_WPA_KEY_MAX_LENGTH 63

// Length of key in bytes. Valid values are 5 and 13.
#define WL_WEP_KEY_MAX_LENGTH 13

// Size of a MAC-address or BSSID
#define WL_MAC_ADDR_LENGTH 6

// Size of a MAC-address or BSSID
#define WL_IPV4_LENGTH 4

// Maximum size of a SSID list
#define WL_NETWORKS_LIST_MAXNUM	10

// Maxmium number of socket
#define	MAX_SOCK_NUM		4

// Socket not available constant
#define SOCK_NOT_AVAIL  255

// Default state value for Wifi state field
#define NA_STATE -1

//Maximum number of attempts to establish wifi connection
#define WL_MAX_ATTEMPT_CONNECTION 10

#define WL_FW_VER_LENGTH 10

#define NO_SOCKET_AVAIL 255




typedef enum eProtMode {TCP_MODE, UDP_MODE} tProtMode;


typedef enum {
        WL_FAILURE = -1,
        WL_SUCCESS = 1,
} wl_error_code_t;

/* Authentication modes */
enum wl_auth_mode {
        AUTH_MODE_INVALID,
        AUTH_MODE_AUTO,
        AUTH_MODE_OPEN_SYSTEM,
        AUTH_MODE_SHARED_KEY,
        AUTH_MODE_WPA,
        AUTH_MODE_WPA2,
        AUTH_MODE_WPA_PSK,
        AUTH_MODE_WPA2_PSK
};


typedef enum {
	WL_NO_SHIELD = 255,
	WL_IDLE_STATUS = 0,
	WL_NO_SSID_AVAIL,
	WL_SCAN_COMPLETED,
	WL_CONNECTED,
	WL_CONNECT_FAILED,
	WL_CONNECTION_LOST,
	WL_DISCONNECTED
} wl_status_t;

/* Encryption modes */
enum wl_enc_type {  /* Values map to 802.11 encryption suites... */
	ENC_TYPE_WEP  = 5,
	ENC_TYPE_TKIP = 2,
	ENC_TYPE_CCMP = 4,
	/* ... except these two, 7 and 8 are reserved in 802.11-2007 */
	ENC_TYPE_NONE = 7,
	ENC_TYPE_AUTO = 8
};

enum wl_tcp_state {
	CLOSED      = 0,
	LISTEN      = 1,
	SYN_SENT    = 2,
	SYN_RCVD    = 3,
	ESTABLISHED = 4,
	FIN_WAIT_1  = 5,
	FIN_WAIT_2  = 6,
	CLOSE_WAIT  = 7,
	CLOSING     = 8,
	LAST_ACK    = 9,
	TIME_WAIT   = 10
};



class EspDrv
{

public:

    static void wifiDriverInit(unsigned long baud);

    static void reset();


	
    /* Start Wifi connection with passphrase
     *
     * param ssid: Pointer to the SSID string.
     * param passphrase: Passphrase. Valid characters in a passphrase must be between ASCII 32-126 (decimal).
     */
    static bool wifiConnect(char* ssid, const char *passphrase);


    /*
	* Start the Access Point
	*/
	static bool wifiStartAP(char* ssid, const char* pwd, uint8_t channel, uint8_t enc);
	
	
    /*
	 *Set ip configuration disabling dhcp client
	*/
    static void config(uint32_t local_ip);

    /* Set DNS ip configuration
	*
	* param validParams: set the number of parameters that we want to change
	* 					 i.e. validParams = 1 means that we'll change only dns_server1
	* 					 	  validParams = 2 means that we'll change dns_server1 and dns_server2
	* param dns_server1: DNS server1 configuration
	* param dns_server2: DNS server2 configuration
	*/
    //static void setDNS(uint8_t validParams, uint32_t dns_server1, uint32_t dns_server2);

    /*
     * Disconnect from the network
     *
     * return: WL_SUCCESS or WL_FAILURE
     */
    static int8_t disconnect();

    /*
     * 
     *
     * return: one value of wl_status_t enum
     */
    static uint8_t getConnectionStatus();

    /*
     * Get the interface MAC address.
     *
     * return: pointer to uint8_t array with length WL_MAC_ADDR_LENGTH
     */
    static uint8_t* getMacAddress();

    /*
     * Get the interface IP address.
     *
     * return: copy the ip address value in IPAddress object
     */
    static void getIpAddress(IPAddress& ip);

	static void getIpAddressAP(IPAddress& ip);


    /*
     * Return the current SSID associated with the network
     *
     * return: ssid string
     */
    static char* getCurrentSSID();

    /*
     * Return the current BSSID associated with the network.
     * It is the MAC address of the Access Point
     *
     * return: pointer to uint8_t array with length WL_MAC_ADDR_LENGTH
     */
    static uint8_t* getCurrentBSSID();

    /*
     * Return the current RSSI /Received Signal Strength in dBm)
     * associated with the network
     *
     * return: signed value
     */
    static int32_t getCurrentRSSI();


    /*
     * Get the firmware version
     */
    static char* getFwVersion();
	
	
	////////////////////////////////////////////////////////////////////////////
	// Client/Server methods
	////////////////////////////////////////////////////////////////////////////
	
    /*
	* Start a TCP server on the specified port
	*/
	static void startServer(uint16_t port);
	
    static bool startClient(const char* host, uint16_t port, uint8_t sock, uint8_t protMode=TCP_MODE);

    static void stopClient(uint8_t sock);

    static uint8_t getServerState(uint8_t sock);

    static uint8_t getClientState(uint8_t sock);

    static bool getData(uint8_t connId, uint8_t *data, uint8_t peek = 0);

    static bool getDataBuf(uint8_t sock, uint8_t *data, uint16_t *len);

    static bool sendData(uint8_t sock, const uint8_t *data, uint16_t len);

    static uint16_t availData(uint8_t connId);
	
	
	////////////////////////////////////////////////////////////////////////////
	// Non standard methods
	////////////////////////////////////////////////////////////////////////////

	/*
	* Ping a host.
	*/
	static bool ping(const char *host);
	


////////////////////////////////////////////////////////////////////////////////

private:


#ifndef HAVE_HWSERIAL1
	static SoftwareSerial Serial1;
#endif

	static long _bufPos;
	static uint8_t _connId;
	
	// settings of requested network
	//char 	_networkSsid[WL_NETWORKS_LIST_MAXNUM][WL_SSID_MAX_LENGTH];
	//int32_t 	_networkRssi[WL_NETWORKS_LIST_MAXNUM];
	//uint8_t 	_networkEncr[WL_NETWORKS_LIST_MAXNUM];

	// firmware version string
	static char 	fwVersion[WL_FW_VER_LENGTH];

	// settings of current selected network
	static char 	_ssid[WL_SSID_MAX_LENGTH];
	static uint8_t 	_bssid[WL_MAC_ADDR_LENGTH];
	static uint8_t 	_mac[WL_MAC_ADDR_LENGTH];
	static uint8_t  _localIp[WL_IPV4_LENGTH];
	//uint8_t  _subnetMask[WL_IPV4_LENGTH];
	//uint8_t  _gatewayIp[WL_IPV4_LENGTH];

	static char cmdBuf[200];

	// the ring buffer is used to search the tags in the stream
	static RingBuffer ringBuf;

	
	static int sendCmd(const __FlashStringHelper* cmd, int timeout=1000);
	static int sendCmd(const char* cmd, int timeout=1000);
	static bool sendCmd(const __FlashStringHelper* cmd, const char* startTag, const char* endTag, char* outStr, int outStrLen);
	static bool sendCmd(const char* cmd, const char* startTag, const char* endTag, char* outStr, int outStrLen);
	static int readUntil(int timeout, const char* tag=NULL, bool findTags=true);
	

	static void espEmptyBuf(bool warn=true);
	
	static int timedRead();

	
	friend class WiFiEspServer;
};

extern EspDrv espDrv;

#endif
