"""Send the freemium strategy email via Gmail API."""
import os, base64
from email.mime.text import MIMEText
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]

BODY = """Free vs. Paid Split Strategy

Principle: Give one hero call per popular animal in Free - enough to use the app in the field and see quality - but lock the depth and variety behind the paywall.


FREE TIER (~15 calls, covers all 4 categories)
=============================================

WATERFOWL (3 free):
- Mallard Greeting Call - most hunted waterfowl, instant value
- Canada Goose Honk - every goose hunter needs this
- Wood Duck Whistle - distinctive, popular

BIG GAME (4 free):
- Whitetail Buck Grunt - core deer call, covers 90% of hunters
- Whitetail Doe Bleat - second most common deer call
- Elk Bull Bugle - iconic, draws elk hunters in
- Moose Cow Call - essential for moose hunters

PREDATORS (3 free):
- Coyote Lone Howl - most popular predator call
- Rabbit Distress - universal predator attractant
- Red Fox Scream - exciting, shows app quality

LAND BIRDS (4 free):
- Turkey Hen Yelp - most important turkey call
- Crow Standard Caw - support call every hunter uses
- Mourning Dove Perch Coo - popular game bird
- Barred Owl Hoot - classic, used to locate turkeys

15 free calls = ~26 MB of audio (vs 76 calls all bundled)


PAID TIER (~61 calls) - The stuff they'll drool over
====================================================

Full Whitetail Suite (9 locked):
Snort Wheeze, Buck Challenge, Tending Grunt, Estrus Bleat, Fawn Distress,
Lost Fawn, Dominant Grunt, Social Grunt, Tending Grunt Alt
>> Every serious deer hunter wants ALL the rut calls

Wolf Pack (5 calls):
Howl, Bark, Growl, Yelp, Whine
>> Exotic, exciting - "I need this" factor

Full Bobcat Collection (8+ calls):
Growl, Deep Growl, Vocalization, Hiss, Scream, Purr, Chirp, Yowl, Bark, Howl
>> Depth = perceived value

Specialty Big Game:
Fallow Deer, Red Stag, Caribou, Pronghorn, Mule Deer, Black Bear (Bawl + Cub Distress)
>> Dream hunts / aspirational content

Advanced Waterfowl:
Feed Chatter, Teal, Snow Goose, Specklebelly, Pintail, Canvasback, Wood Duck Sit, Lonesome Hen
>> Serious waterfowler completionist bait

Pro Turkey:
Gobble, Cluck & Purr, Tree Yelp
>> "I already use the Hen Yelp, I need more"

Wild Hog (4 calls):
Grunt, Bark, Loud Squeal, Squeal
>> Popular category, fully locked = enticing

Mountain Lion / Cougar (2 calls):
Scream, Puma Scream
>> Exciting predator content

Gray Fox, Raccoon, Badger:
>> Niche predator fills

Great Horned Owl, Ruffed Grouse, Pheasant, Quail, Woodcock, Crow Fight:
>> Advanced birding content


SIZE OPTIMIZATION STRATEGY
==========================

Beyond the free/paid split, there are two big wins:

1. ON-DEMAND DOWNLOAD
   Don't bundle locked audio in the APK. Download when purchased.
   Drops APK from ~198 MB to ~26 MB (free calls only).

2. COMPRESS TO OGG VORBIS
   WAV is huge. OGG at 128kbps is 10x smaller with imperceptible
   quality loss for playback. Pitch/duration analysis data is already
   in the JSON so we don't need lossless WAV for that.
   Combined: APK could drop to ~15-20 MB which is Play Store friendly.
"""


def main():
    script_dir = os.path.dirname(__file__)
    token_path = os.path.join(script_dir, "token.json")
    creds_path = os.path.join(script_dir, "credentials.json")
    creds = None

    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_path, "w") as f:
                f.write(creds.to_json())
        else:
            from google_auth_oauthlib.flow import InstalledAppFlow
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
            with open(token_path, "w") as f:
                f.write(creds.to_json())

    service = build("gmail", "v1", credentials=creds)

    msg = MIMEText(BODY)
    msg["to"] = "benchmarkappsllc@gmail.com"
    msg["from"] = "benchmarkappsllc@gmail.com"
    msg["subject"] = "just some thoughts"

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode()
    result = service.users().messages().send(userId="me", body={"raw": raw}).execute()
    print(f"Email sent! Message ID: {result['id']}")


if __name__ == "__main__":
    main()
