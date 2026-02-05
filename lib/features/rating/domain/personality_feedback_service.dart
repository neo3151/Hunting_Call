import 'dart:math';

/// Service that generates brutally honest personality feedback based on score
class PersonalityFeedbackService {
  static final Random _random = Random();

  /// Get a personality feedback message based on the score
  static String getFeedback(double score) {
    if (score >= 95) return _legendary[_random.nextInt(_legendary.length)];
    if (score >= 85) return _expert[_random.nextInt(_expert.length)];
    if (score >= 75) return _proficient[_random.nextInt(_proficient.length)];
    if (score >= 65) return _average[_random.nextInt(_average.length)];
    if (score >= 50) return _struggling[_random.nextInt(_struggling.length)];
    if (score >= 35) return _poor[_random.nextInt(_poor.length)];
    return _terrible[_random.nextInt(_terrible.length)];
  }

  // 95-100: LEGENDARY
  static final List<String> _legendary = [
    "That wasn't a call. That was a masterclass. Frame this performance.",
    "You just made every other caller look like they're playing with toy instruments.",
    "The animals aren't just listening—they're taking notes.",
    "If calls were art, this would be hanging in the Louvre.",
    "Stop. You've peaked. There's nowhere to go but down from here.",
    "That was so clean it should be used as the new reference standard.",
    "You didn't just nail it. You drove the nail, built the house, and sold it for profit.",
    "I'm genuinely uncomfortable with how perfect that was.",
    "Somewhere, a wildlife documentary narrator just felt inadequate.",
    "That call was illegal in 37 states due to excessive excellence.",
    "You just 'locked wings' on a literal computer algorithm. Unreal.",
    "Pure 'public land' magic. No decoys needed with a voice like that.",
    "The Alpha of the pack just resigned. You're the boss now.",
    "If you were any more realistic, I'd have to check you for a pulse and feathers.",
  ];

  // 85-94: EXPERT
  static final List<String> _expert = [
    "That's the kind of performance that makes beginners quit.",
    "You're operating at a level that should require a license.",
    "If you bottled that skill, you'd be a millionaire.",
    "That was chef's kiss perfection. No notes.",
    "You just made three years of someone else's practice look pointless.",
    "The bar has been raised. By you. Again.",
    "That's what separates the pros from the pretenders.",
    "If confidence was a sound, it would sound exactly like that.",
    "You're not just good. You're 'teach a masterclass' good.",
    "That performance belongs on a highlight reel.",
    "You're calling 'em into the kitchen. Hope you brought enough plates.",
    "That tone is cleaner than a brand-new custom acrylic call.",
    "You've got that 'late-season' finesse. Those birds don't stand a chance.",
  ];

  // 75-84: PROFICIENT
  static final List<String> _proficient = [
    "Solid work. You're officially past the embarrassing stage.",
    "That's respectable. Not spectacular, but definitely respectable.",
    "You won't win awards, but you won't get laughed at either.",
    "Good enough to not be the weak link. Aim higher.",
    "You've reached 'competent.' Congratulations on baseline adequacy.",
    "That's the performance of someone who actually practices. Rare these days.",
    "Decent showing. You're in the top half, which isn't nothing.",
    "You're good, but you're not 'quit your day job' good. Yet.",
    "That was fine. And 'fine' is the enemy of 'great.'",
    "You've got the fundamentals down. Now comes the hard part.",
    "Close enough to fill a limit, but keep practicing those transitions.",
    "You're not 'sky busting' anymore. Welcome to the decoys.",
  ];

  // 65-74: AVERAGE / NEEDS WORK
  static final List<String> _average = [
    "That was aggressively mediocre. Like, impressively average.",
    "You're the human equivalent of a participation trophy.",
    "Somewhere, an animal heard that and filed a noise complaint.",
    "That's what happens when 'good enough' becomes your standard.",
    "You're stuck in the land of 'meh.' Population: you.",
    "I've heard elevator music with more personality than that call.",
    "That was the calling equivalent of beige wallpaper. Technically exists, nobody cares.",
    "You know what's worse than failing spectacularly? Succeeding boringly.",
    "That performance screamed 'I didn't really try and it shows.'",
    "Congrats on achieving maximum unremarkable.",
    "You're 'educating' the birds. They're learning to avoid you.",
    "That's the calling equivalent of a 'missed at ten yards.' Focus!",
    "Basic. Like a factory-tuned plastic call from a big-box store.",
  ];

  // 50-64: STRUGGLING
  static final List<String> _struggling = [
    "That sounded like a cry for help disguised as a duck call.",
    "The animals heard that and immediately updated their predator alert systems.",
    "You're not struggling with the technique—you're wrestling it to the ground and losing.",
    "That wasn't practice. That was audio evidence of a crime.",
    "I've heard better sounds from a dog toy with a puncture.",
    "You know what the problem is? Everything. The problem is everything.",
    "If that was your best effort, I'm deeply concerned about your worst.",
    "That call just set wildlife conservation back a decade.",
    "You're making sounds, just not the right ones. Or any good ones.",
    "That was bad enough to make me question if you have ears.",
    "Somewhere, a Hunter Education instructor just felt a disturbance.",
    "The only thing that call attracted was pity.",
    "You're 'blowing out' the reed. Back off the pressure, champ.",
    "Sounds like a kazoo in a wind tunnel. Not ideal for the blind.",
    "That's a 'flock disclaimer.' One note and they're gone.",
  ];

  // 35-49: POOR
  static final List<String> _poor = [
    "That wasn't a call. That was a war crime against sound itself.",
    "I've heard smoother sounds from a cat in a blender. And I'm not joking.",
    "You just scared every animal in a 10-mile radius into therapy.",
    "That sound violated the Geneva Convention on acoustic warfare.",
    "If terrible had a voice, it would sound exactly like that. Exactly.",
    "You know what that call attracted? Nothing. Absolutely nothing. Not even flies.",
    "That wasn't practice—that was performance art titled 'Total Failure.'",
    "I'm not angry. I'm just... disappointed doesn't even cover it.",
    "You managed to make noise pollution sound like a compliment.",
    "That call is literally what wildlife uses to scare away predators.",
    "I've heard better music from a fax machine having a seizure.",
    "That was so bad I'm starting to think you're doing it wrong on purpose.",
    "The dumpster fire called. It wants its aesthetic back.",
    "You just proved that some people shouldn't have access to recording equipment.",
    "Total 'sky buster' energy. You're scaring 'em off into the next county.",
    "Stop. Just stop. You're making the decoys look bad.",
  ];

  // 0-34: TERRIBLE
  static final List<String> _terrible = [
    "I don't have words. I have sounds. Horrified, anguished sounds.",
    "That was a hate crime against the concept of calling.",
    "You just invented a new form of terrible that scientists can't yet explain.",
    "If failure was an Olympic sport, you'd be disqualified for doping with pure incompetence.",
    "That sound made my ears file for divorce from my head.",
    "I've heard more musical flatulence coming from a tuba with dysentery.",
    "That wasn't a call. That was a cry for help from your vocal cords.",
    "You somehow managed to disappoint microphones. MICROPHONES.",
    "The only thing that call summoned was regret. Deep, existential regret.",
    "I'm forwarding this to my therapist because I need help processing what I just heard.",
    "That was so catastrophically bad it qualifies as a natural disaster.",
    "You didn't miss the mark. You missed the entire shooting range, the parking lot, and three neighboring counties.",
    "That sound just got added to the list of things banned by the UN.",
    "If I could unsubscribe from your vocal cords, I would. Twice.",
    "That was weapons-grade terrible. Like, could-be-used-in-interrogations terrible.",
    "You make drunk karaoke sound like Carnegie Hall.",
    "That call was so bad it retroactively ruined your previous attempts.",
    "I've heard better sounds from a garbage disposal eating silverware.",
    "You just proved that rock bottom has a basement. With sub-basements.",
    "That performance made me reconsider my stance on public shaming.",
    "You just 'educated' the entire state. Everyone stay home.",
    "I've seen decoys with more life and better tone than that.",
    "That sound is the reason bag limits exist—to protect us from you.",
  ];
}
