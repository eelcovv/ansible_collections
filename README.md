# README #

Dit document bevat de instructie en settings file om een [LXD](https://linuxcontainers.org/) virtuele machine met 
behulp van [Ansible](https://docs.ansible.com) op te zetten. Het richt zich specifiek op het inrichten van van
[Oracle Free tier](https://www.oracle.com/cloud/free/)

### Stappen om een machine op te zetten ###

#### Maak een nieuwe Ubuntu machine en installeer het volgende:

~~~
apt install snapd
snap install lxd
apt install git
apt install libsecret-tools
ssh-keygen
apt install python3
apt install pip
apt install whois
pip install ansible
pip install argcomplete
~~~

##### Voorbereiding lxd

Om lxd voor de eerste keer te configureren kan je het volgende commando runnen:

~~~
lxd init
~~~


##### Creëer twee nieuwe Linux ubuntu machines 

Creeer eerst een ubuntu machine naam *ununtudsk*  en  *ununtuweb* 


~~~
lxc launch images:ubuntu/22.10 oracledsk
lxc launch images:ubuntu/22.10 oracleweb
~~~

Daar

Als je protectie op je image wilt toevoegen doe je:

~~~
lxc config set oracledsk security.protection.delete true
lxc config set oracleweb security.protection.delete true
~~~

Hiermee voorkom je dat je een aangemaakte image per ongeluk delete met het command *lxc delete oraclesdsk*. Je
moet om een image te deleten eerst de flag weer op false zetten. 

We installeren ubuntu ipv mint omdat ubuntu makkelijker met xrdp kan connecten. Met mint is me dit niet gelukt

Vraag een lijst van je machine op met 


~~~
sudo lxc ls
~~~

Het resultaat zou er zo uit moeten zien:

~~~
+-----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
|   NAME    |  STATE  |        IPV4         |                     IPV6                      |   TYPE    | SNAPSHOTS |
+-----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
| oracledsk | RUNNING | 10.25.39.181 (eth0) | fd42:3c03:b1bf:e3f2:216:3eff:fefa:eb48 (eth0) | CONTAINER | 0         |
+-----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
| oracleweb | RUNNING | 10.25.39.177 (eth0) | fd42:3c03:b1bf:e3f2:216:3eff:fea9:9c83 (eth0) | CONTAINER | 0         |
+-----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
~~~

Je kan al testen of je kunt inloggen door te doen:

```
lxc shell oracledsk

```

Je gebruikt het lxc shell commando om in te loggen. Ssh is nog niet nodig en dat kan ook niet omdat we dat nog niet
op de clients geïnstalleerd hebben.  Dat doen we zo met ansible.

##### Zo geef je de netwerkinstellingen op

Het doel van dit stuk is om je interne adressen van je images ook van buiten te kunnen benaderen. We doen dat even
voor de *ubuntudsk* server. Om de server met ssh te kunnen benaderen moet je eerst openssh installeren. Eigenlijk 
doen we dat later met de ansible playbook, maar als je het zonder ansible wilt doen dan kan je eest zonder ssh inloggen
met het *lxc shell oracledsk* commando en dan met *apt install* zowel *ssh* als *openssh-client* te installeren. 

Om de netwerkinstellingen te doen, maken we eerst een inventarisatie van je huidige image met:

```
lxc info ubuntudsk
```

Gebruik de naam van je brug (*lxbr0*) om je netwerk door te verbinden

```
lxc network list
lxc network forward create lxdbr0 <interne ip address>
lxc network forward port add lxdbr0 <interne_ip_address> tcp 2022  <ip van image> 22
```

De naam *lxdbr0* verwijst naar de naam van de bridge naar je client. Het IP adres is het adres van je Ubuntu host. 
Via de ssh port *2022* wordt deze naar je locale ip van de image  geforward.


Concreet heb ik voor de oracle data base de volgende poorten aangemaakt

```
lxc network forward port add lxdbr0  10.0.0.143 tcp 2023 10.25.39.177  22
lxc network forward port add lxdbr0  10.0.0.143 tcp 2023 10.25.39.181  22
lxc network forward port add lxdbr0  10.0.0.143 tcp 2080 10.25.39.181  3389
```

De laatste is nodig om vanuit windows met rdp te connecten. De eerste twee gebruik je met Reminni vanuit linux. Je tunnelt dan via de ssh poort 22

Belangrijk is dat het IP adres van de host door oracle veranderd wordt naar een intern ip adres. Je moet dan niet 
141.148.245.90 gebruiken waarmee je van buiten mee inlogt, maar het ip adres dat je krijgt als je doet:


```
ip ad
```

Concreet doe je dus:

```
lxc network forward create lxdbr0 10.0.0.143
```

met 10.0.0.143 het interne ip address van oracle dat je met *ip ad* vindt.

Dit interne IP adres kan je ook in de oracle dashboard vinden.

Daarnaast moet je ook op de oracle dash board kijken of je poort nummers geforward worden. Dit vind je onder:

```
Netwerken > Virtuele cloudnetwerken > vcn-20230102-1108 > Details beveiligingslijst > Ingangsregels
```

Hier moet je zorgen dat deze regel te zien is door 'Invoerregels toevoegen' te geven

```
Nee	0.0.0.0/0	TCP	Alles	2000-3000		TCP-verkeer voor poorten: 2000-3000 	 SSH
Nee	0.0.0.0/0	TCP	Alles	3389			TCP-verkeer voor poorten: 2000-3000 	 RDP
```

Je kan nu van buiten inloggen  met

```
ssh -p 2022 eelco@141.148.245.90
```

en files kopiëren met

```
scp -P 2022 fienaam eelco@141.148.245.90:~ 
```


Als je nog geen gebruiker eelco hebt gemaakt kan je ook al root inloggen. De gebruikers kan je zelf handmatig aanmaken, 
maar we doen het ook met ansible, zoals hieronder beschreven. 

##### Installeer de plug-in om je nieuwe machine van buitenaf op te zetten

We gaan nu ansible gebruiken om software op de machines te installeren. We beginnen met het toevoegen van wat 
functionaliteit. Doe:

~~~
ansible-galaxy collection install community.general -f
~~~

##### Installeer de plug-in om je nieuwe machine van buitenaf op te zetten

##### Installeer de utility *mkpasswd* met behulp van *apt install whois* en run dan


```
mkpasswd --method=sha-512
```

De gegenereerde hashkey kan je als password in je *mintdesk.yml* voor de user mee geven in de file

```
collections/ansible_collections/eelcovv/ldx_webdev_server/roles/system/vars/main.yml

```
##### De ansible playbook kan je runnen met

```
ansible-playbook -i collections/ansible_collections/eelcovv/ldx_webdev_server/plugins/inventory/inventory.yml main.yml
```

De *main.yml* start de playbook voor de server en desktop. Je kan ook alleen het instellen van je desktop doen door
ipv  *main.yml*  *all_desktops.yml* mee te geven. 

Met welke hosts de desktop overeen komen wordt in de inventory file vast gelegd, zie:

```
collections/ansible_collections/eelcovv/ldx_webdev_server/plugins/inventory/inventory.yml
```

het stukje 

```
  children:
      local:
        vars:
          ansible_lxd_remote: local
      webservers:
        hosts:
          oracleweb:     # dit is de naam die je aan je image van je ubuntu webserver gegeven hebt 
      desktops:
        hosts:
          oracledsk:     # dit is de naam die je aan je image van je ubuntu desktop gegeven hebt
```

Je hebt dus 2 groepen servers: *webservers* en *desktops*. Met deze playbook kan je de installatie stappen voor
de 2 groepen apart uitvoeren. Daarnaast heb je nog installatie stappen die voor beide groepen gelden. Deze worden
uitgevoerd met *all_common.yml*. Je moet deze altijd draaien voordat je *all_desktops.yml* of *all_webservers.yml* 
draait. 


##### Instellen van mambaforge

Installeer de micromamba conda environment

```
ansible-galaxy install mambaorg.micromamba

```

##### Wat handige lxc commando's 

Lijst van alle containers:
```
lxc ls
```

Container deleten
```
lxc delete mintdesk
```

Een lijst van al je forward porten krijgen

```
lxc network forward show lxdbr0 10.0.0.143
```

Om 1 port de deleten doe je

```
sudo lxc network forward port remove lxdbr0 10.0.0.143 tcp 2080
```

##### RDP verbinding met remina maken

Vul bij Basic in voor de server 'localhost' in en bij het tabblad *SSH tunnel* voor *Custom* het ip address + port van je ssh *144.91.125.45:2022*

Nu zou je moeten kunnen inloggen met Remmina 

##### Wat handige tips voor trouble shooting

Als er iets fout gaat doe je:

```
journalctl
```

En kijk je aan het eind wat de foutmelding is  

Een cheat-sheet kan je hier vinden: https://gist.github.com/berndbausch/a6835150c7a26c88048763c0bd739be6


Direct inloggen vanuit ubuntu_host kan met 

```
lxc shell ubuntu

```

Als je niet met ssh in kan loggen dan kan je  moet je waarschijnlijk de */etc/ssh/ssh/sshd_config* file editten en uncomment de regel


```
PasswordAuthentication yes
```

Netter is om een file toe te voegen met daaarin deze regel:

```
/etc/ssh/sshd_config.d/99-cloudimg-settings.conf
```

Als je een error over de list dir krijgt die locked is kan je dit doen:

```
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean
sudo apt-get update
```

Wat commando's om te troubel shooten

ip ad
ssh -p 2023 eelco@10.0.0.143
iptables-save
nft list table inet lxd


###### Firewall instellen

Als je problemen met je firewall hebt, dan zou het kunnen dat de lxd firewall interfereert met de firewall van lxd.
De oplossing is dan om de lxd firewall uit te zetten. Dat wordt hier uitgelegd.


Check eerst of je een firewall op je server hebt draaien met het commando:

~~~
nft list ruleset
~~~

of

~~~
ufw status
~~~

Als je al een firewall hebt, kan je de firewall van lxd uitzetten door te doen:

~~~
lxc network set lxdbr0 ipv4.firewall false
lxc network set lxdbr0 ipv6.firewall false
~~~

Vervolgens moet je de bridge nog aan de firewall regels toevoegen met

~~~
firewall-cmd --zone=trusted --change-interface=lxdbr0 --permanent
firewall-cmd --reload
~~~

Als het commando *firewall-cmd* niet herkend wordt kan je het zo installeren:

~~~
apt install firewalld
~~~
